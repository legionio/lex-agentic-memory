# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Trace
          module Helpers
            # Cache-backed store using Legion::Cache (Memcached/Redis).
            # Keeps a local copy in memory, syncs to/from cache on load/flush.
            # Call `flush` after a batch of writes, or it auto-flushes when dirty.
            # Call `reload` to pull latest state from cache (e.g. after another process wrote).
            class CacheStore
              TRACES_KEY = 'legion:memory:traces'
              ASSOC_KEY  = 'legion:memory:associations'
              TTL        = 86_400 # 24 hours

              attr_reader :traces, :associations

              def initialize
                Legion::Logging.info '[memory] CacheStore initialized (memcached-backed)'
                @traces       = Legion::Cache.get(TRACES_KEY) || {}
                @associations = Legion::Cache.get(ASSOC_KEY) || {}
                @dirty        = false
                Legion::Logging.info "[memory] CacheStore loaded #{@traces.size} traces from cache"
              end

              def store(trace)
                @traces[trace[:trace_id]] = trace
                @dirty = true
                trace[:trace_id]
              end

              def get(trace_id)
                @traces[trace_id]
              end

              def delete(trace_id)
                @traces.delete(trace_id)
                @associations.delete(trace_id)
                @associations.each_value { |links| links.delete(trace_id) }
                @dirty = true
              end

              def retrieve_by_type(type, min_strength: 0.0, limit: 100)
                @traces.values
                       .select { |t| t[:trace_type] == type && t[:strength] >= min_strength }
                       .sort_by { |t| -t[:strength] }
                       .first(limit)
              end

              def retrieve_by_domain(domain_tag, min_strength: 0.0, limit: 100)
                @traces.values
                       .select { |t| t[:domain_tags].include?(domain_tag) && t[:strength] >= min_strength }
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

                @associations[trace_id_a] ||= {}
                @associations[trace_id_b] ||= {}
                @associations[trace_id_a][trace_id_b] = (@associations[trace_id_a][trace_id_b] || 0) + 1
                @associations[trace_id_b][trace_id_a] = (@associations[trace_id_b][trace_id_a] || 0) + 1

                threshold = Helpers::Trace::COACTIVATION_THRESHOLD
                link_traces(trace_id_a, trace_id_b) if @associations[trace_id_a][trace_id_b] >= threshold
                @dirty = true
              end

              def all_traces(min_strength: 0.0)
                @traces.values.select { |t| t[:strength] >= min_strength }
              end

              def count
                @traces.size
              end

              def firmware_traces
                retrieve_by_type(:firmware)
              end

              def walk_associations(start_id:, max_hops: 12, min_strength: 0.1)
                return [] unless @traces.key?(start_id)

                results = []
                visited = Set.new([start_id])
                queue   = [[start_id, 0, [start_id]]]

                until queue.empty?
                  current_id, depth, path = queue.shift
                  current = @traces[current_id]
                  next unless current

                  current[:associated_traces].each do |neighbor_id|
                    next if visited.include?(neighbor_id)

                    neighbor = @traces[neighbor_id]
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

              # Write local state to cache
              def flush
                return unless @dirty

                Legion::Cache.set(TRACES_KEY, @traces, TTL)
                Legion::Cache.set(ASSOC_KEY, strip_default_procs(@associations), TTL)
                @dirty = false
                Legion::Logging.debug "[memory] CacheStore flushed #{@traces.size} traces to cache"
              end

              # Pull latest state from cache (after another process wrote)
              def reload
                @traces       = Legion::Cache.get(TRACES_KEY) || {}
                @associations = Legion::Cache.get(ASSOC_KEY) || {}
                @dirty        = false
                Legion::Logging.debug "[memory] CacheStore reloaded #{@traces.size} traces from cache"
              end

              private

              def strip_default_procs(hash)
                hash.each_with_object({}) do |(k, v), plain|
                  plain[k] = v.is_a?(Hash) ? {}.merge(v) : v
                end
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
