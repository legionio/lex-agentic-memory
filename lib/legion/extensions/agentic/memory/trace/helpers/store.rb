# frozen_string_literal: true

require 'json'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Trace
          module Helpers
            # In-memory store for development and testing.
            # Production deployments should use a PostgreSQL + Redis backed store.
            class Store
              attr_reader :traces, :associations

              def initialize
                @mutex = Mutex.new
                @traces = {}
                @associations = Hash.new { |h, k| h[k] = Hash.new(0) }
                load_from_local
              end

              def store(trace)
                @mutex.synchronize { @traces[trace[:trace_id]] = trace }
                trace[:trace_id]
              end

              def get(trace_id)
                @traces[trace_id]
              end

              def delete(trace_id)
                @mutex.synchronize do
                  @traces.delete(trace_id)
                  @associations.delete(trace_id)
                  @associations.each_value { |links| links.delete(trace_id) }
                end
              end

              def retrieve_by_type(type, min_strength: 0.0, limit: 100)
                snapshot = @mutex.synchronize { @traces.values }
                snapshot.select { |t| t[:trace_type] == type && t[:strength] >= min_strength }
                        .sort_by { |t| -t[:strength] }
                        .first(limit)
              end

              def retrieve_by_domain(domain_tag, min_strength: 0.0, limit: 100)
                snapshot = @mutex.synchronize { @traces.values }
                snapshot.select { |t| t[:domain_tags].include?(domain_tag) && t[:strength] >= min_strength }
                        .sort_by { |t| -t[:strength] }
                        .first(limit)
              end

              def retrieve_associated(trace_id, min_strength: 0.0, limit: 20)
                trace = @traces[trace_id]
                return [] unless trace

                trace[:associated_traces]
                  .filter_map { |id| @traces[id] }
                  .select { |t| t[:strength] >= min_strength }
                  .sort_by { |t| -t[:strength] }
                  .first(limit)
              end

              def record_coactivation(trace_id_a, trace_id_b)
                return if trace_id_a == trace_id_b

                @mutex.synchronize do
                  @associations[trace_id_a][trace_id_b] += 1
                  @associations[trace_id_b][trace_id_a] += 1

                  threshold = Helpers::Trace::COACTIVATION_THRESHOLD
                  link_traces(trace_id_a, trace_id_b) if @associations[trace_id_a][trace_id_b] >= threshold
                end
              end

              def all_traces(min_strength: 0.0)
                snapshot = @mutex.synchronize { @traces.values }
                snapshot.select { |t| t[:strength] >= min_strength }
              end

              def count
                @traces.size
              end

              def synchronize(&) = @mutex.synchronize(&)

              def firmware_traces
                retrieve_by_type(:firmware)
              end

              def walk_associations(start_id:, max_hops: 12, min_strength: 0.1)
                snapshot = @mutex.synchronize { @traces.dup }
                return [] unless snapshot.key?(start_id)

                results  = []
                visited  = Set.new([start_id])
                queue    = [[start_id, 0, [start_id]]]

                until queue.empty?
                  current_id, depth, path = queue.shift
                  next unless (current = snapshot[current_id])

                  current[:associated_traces].each do |neighbor_id|
                    next if visited.include?(neighbor_id)

                    neighbor = snapshot[neighbor_id]
                    next unless neighbor
                    next unless neighbor[:strength] >= min_strength

                    visited << neighbor_id
                    neighbor_path = path + [neighbor_id]
                    results << { trace_id: neighbor_id, depth: depth + 1, path: neighbor_path }
                    queue << [neighbor_id, depth + 1, neighbor_path] if depth + 1 < max_hops
                  end
                end

                results
              end

              def save_to_local
                return unless defined?(Legion::Data::Local) && Legion::Data::Local.connected?
                return unless Legion::Data::Local.connection.table_exists?(:memory_traces)

                db = Legion::Data::Local.connection
                traces_snapshot = @mutex.synchronize { @traces.dup }

                traces_snapshot.each_value do |trace|
                  row = serialize_trace_for_db(trace)
                  existing = db[:memory_traces].where(trace_id: trace[:trace_id]).first
                  if existing
                    db[:memory_traces].where(trace_id: trace[:trace_id]).update(row)
                  else
                    db[:memory_traces].insert(row)
                  end
                end

                db_trace_ids = db[:memory_traces].select_map(:trace_id)
                memory_trace_ids = traces_snapshot.keys
                stale_ids = db_trace_ids - memory_trace_ids
                db[:memory_traces].where(trace_id: stale_ids).delete unless stale_ids.empty?

                db[:memory_associations].delete
                @associations.each do |id_a, targets|
                  targets.each do |id_b, count|
                    db[:memory_associations].insert(trace_id_a: id_a, trace_id_b: id_b, coactivation_count: count)
                  end
                end
              end

              def load_from_local
                return unless defined?(Legion::Data::Local) && Legion::Data::Local.connected?
                return unless Legion::Data::Local.connection.table_exists?(:memory_traces)

                db = Legion::Data::Local.connection

                db[:memory_traces].each do |row|
                  @traces[row[:trace_id]] = deserialize_trace_from_db(row)
                end

                db[:memory_associations].each do |row|
                  @associations[row[:trace_id_a]] ||= {}
                  @associations[row[:trace_id_a]][row[:trace_id_b]] = row[:coactivation_count]
                end
              end

              private

              def serialize_trace_for_db(trace)
                payload = trace[:content_payload] || trace[:content]
                {
                  trace_id:                trace[:trace_id],
                  trace_type:              trace[:trace_type].to_s,
                  content:                 payload.is_a?(Hash) ? ::JSON.generate(payload) : payload.to_s,
                  strength:                trace[:strength],
                  peak_strength:           trace[:peak_strength],
                  base_decay_rate:         trace[:base_decay_rate],
                  emotional_valence:       trace[:emotional_valence].is_a?(Hash) ? ::JSON.generate(trace[:emotional_valence]) : nil,
                  emotional_intensity:     trace[:emotional_intensity],
                  domain_tags:             trace[:domain_tags].is_a?(Array) ? ::JSON.generate(trace[:domain_tags]) : nil,
                  origin:                  trace[:origin].to_s,
                  created_at:              trace[:created_at],
                  last_reinforced:         trace[:last_reinforced],
                  last_decayed:            trace[:last_decayed],
                  reinforcement_count:     trace[:reinforcement_count],
                  confidence:              trace[:confidence],
                  storage_tier:            trace[:storage_tier].to_s,
                  partition_id:            trace[:partition_id],
                  associated_traces:       trace[:associated_traces].is_a?(Array) ? ::JSON.generate(trace[:associated_traces]) : nil,
                  parent_id:               trace[:parent_trace_id] || trace[:parent_id],
                  child_ids:               (trace[:child_trace_ids] || trace[:child_ids]).then do |v|
                                             v.is_a?(Array) ? ::JSON.generate(v) : nil
                                           end,
                  unresolved:              trace[:unresolved] || false,
                  consolidation_candidate: trace[:consolidation_candidate] || false
                }
              end

              def deserialize_trace_from_db(row)
                content_raw = row[:content]
                content = begin
                  parsed = ::JSON.parse(content_raw, symbolize_names: true)
                  parsed.is_a?(Hash) ? parsed : content_raw
                rescue StandardError => _e
                  content_raw
                end
                {
                  trace_id:                row[:trace_id],
                  trace_type:              row[:trace_type]&.to_sym,
                  content_payload:         content,
                  content:                 content,
                  strength:                row[:strength],
                  peak_strength:           row[:peak_strength],
                  base_decay_rate:         row[:base_decay_rate],
                  emotional_valence:       begin
                    ::JSON.parse(row[:emotional_valence], symbolize_names: true)
                  rescue StandardError => _e
                    0.0
                  end,
                  emotional_intensity:     row[:emotional_intensity],
                  domain_tags:             begin
                    ::JSON.parse(row[:domain_tags])
                  rescue StandardError => _e
                    []
                  end,
                  origin:                  row[:origin]&.to_sym,
                  created_at:              row[:created_at],
                  last_reinforced:         row[:last_reinforced],
                  last_decayed:            row[:last_decayed],
                  reinforcement_count:     row[:reinforcement_count],
                  confidence:              row[:confidence],
                  storage_tier:            row[:storage_tier]&.to_sym,
                  partition_id:            row[:partition_id],
                  associated_traces:       begin
                    ::JSON.parse(row[:associated_traces])
                  rescue StandardError => _e
                    []
                  end,
                  parent_trace_id:         row[:parent_id],
                  child_trace_ids:         begin
                    ::JSON.parse(row[:child_ids])
                  rescue StandardError => _e
                    []
                  end,
                  unresolved:              row[:unresolved] || false,
                  consolidation_candidate: row[:consolidation_candidate] || false
                }
              end

              def link_traces(id_a, id_b)
                trace_a = @traces[id_a]
                trace_b = @traces[id_b]
                return unless trace_a && trace_b

                max = Helpers::Trace::MAX_ASSOCIATIONS
                trace_a[:associated_traces] << id_b unless trace_a[:associated_traces].include?(id_b) || trace_a[:associated_traces].size >= max
                return if trace_b[:associated_traces].include?(id_a) || trace_b[:associated_traces].size >= max

                trace_b[:associated_traces] << id_a
              end
            end
          end
        end
      end
    end
  end
end
