# frozen_string_literal: true

require_relative 'hot_tier'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Trace
          module Helpers
            # Write-through durable store backed by Legion::Data (PostgreSQL or MySQL).
            # All writes go directly to the database — no in-memory dirty tracking, no flush.
            # Scoped by tenant_id so multiple agents can share the same DB tables safely.
            class PostgresStore
              TRACES_TABLE = :memory_traces
              ASSOCIATIONS_TABLE = :memory_associations

              def initialize(tenant_id: nil, agent_id: nil)
                @tenant_id = tenant_id
                @agent_id  = agent_id || resolve_agent_id
              end

              # Store (upsert) a trace by trace_id.
              # Returns the trace_id on success, nil if the DB is not ready.
              def store(trace)
                return nil unless db_ready?

                row = serialize_trace(trace)
                ds  = db[TRACES_TABLE]
                if db.adapter_scheme == :mysql2
                  ds.insert_conflict(update: row.except(:trace_id)).insert(row)
                else
                  ds.insert_conflict(target: :trace_id, update: row.except(:trace_id)).insert(row)
                end
                HotTier.cache_trace(trace, tenant_id: @tenant_id) if HotTier.available?
                trace[:trace_id]
              rescue StandardError => e
                log_warn("store failed: #{e.message}")
                nil
              end

              # Retrieve a single trace by trace_id (tenant-scoped).
              # Checks the Redis hot tier first; falls through to DB on a miss and caches the result.
              # Returns a trace hash or nil.
              def retrieve(trace_id)
                if HotTier.available?
                  cached = HotTier.fetch_trace(trace_id, tenant_id: @tenant_id)
                  return cached if cached
                end

                return nil unless db_ready?

                row = traces_ds.where(trace_id: trace_id).first
                trace = row ? deserialize_trace(row) : nil
                HotTier.cache_trace(trace, tenant_id: @tenant_id) if HotTier.available? && trace
                trace
              rescue StandardError => e
                log_warn("retrieve failed: #{e.message}")
                nil
              end

              # Retrieve traces by type, ordered by strength descending.
              def retrieve_by_type(type, limit: 100, min_strength: 0.0)
                return [] unless db_ready?

                rows = traces_ds
                       .where(trace_type: type.to_s)
                       .where { strength >= min_strength }
                       .order(Sequel.desc(:strength))
                       .limit(limit)
                       .all
                rows.map { |r| deserialize_trace(r) }
              rescue StandardError => e
                log_warn("retrieve_by_type failed: #{e.message}")
                []
              end

              # Retrieve traces whose domain_tags column contains the given tag string.
              def retrieve_by_domain(tag, limit: 50)
                return [] unless db_ready?

                rows = traces_ds
                       .where(Sequel.like(:domain_tags, "%#{tag}%"))
                       .order(Sequel.desc(:strength))
                       .limit(limit)
                       .all
                rows.map { |r| deserialize_trace(r) }
              rescue StandardError => e
                log_warn("retrieve_by_domain failed: #{e.message}")
                []
              end

              # Return all traces for this tenant.
              def all_traces
                return [] unless db_ready?

                traces_ds.all.map { |r| deserialize_trace(r) }
              rescue StandardError => e
                log_warn("all_traces failed: #{e.message}")
                []
              end

              # Delete a trace and its association rows.
              def delete(trace_id)
                HotTier.evict_trace(trace_id, tenant_id: @tenant_id) if HotTier.available?
                return unless db_ready?

                db[ASSOCIATIONS_TABLE].where(trace_id_a: trace_id).delete
                db[ASSOCIATIONS_TABLE].where(trace_id_b: trace_id).delete
                db[TRACES_TABLE].where(trace_id: trace_id).delete
              rescue StandardError => e
                log_warn("delete failed: #{e.message}")
              end

              # Partial update of a trace by trace_id.
              # Evicts the hot-tier entry so a stale cached version cannot be served.
              def update(trace_id, **fields)
                return unless db_ready?

                db[TRACES_TABLE].where(trace_id: trace_id).update(map_update_fields(fields))
                HotTier.evict_trace(trace_id, tenant_id: @tenant_id) if HotTier.available?
              rescue StandardError => e
                log_warn("update failed: #{e.message}")
              end

              # Create or increment a coactivation association between two traces.
              def record_coactivation(id_a, id_b)
                return unless db_ready?
                return if id_a == id_b

                now = Time.now.utc
                existing = db[ASSOCIATIONS_TABLE]
                           .where(trace_id_a: id_a, trace_id_b: id_b)
                           .first

                if existing
                  db[ASSOCIATIONS_TABLE]
                    .where(id: existing[:id])
                    .update(
                      coactivation_count: existing[:coactivation_count] + 1,
                      updated_at:         now
                    )
                else
                  db[ASSOCIATIONS_TABLE].insert(
                    trace_id_a:         id_a,
                    trace_id_b:         id_b,
                    coactivation_count: 1,
                    linked:             false,
                    tenant_id:          @tenant_id,
                    created_at:         now,
                    updated_at:         now
                  )
                end
              rescue StandardError => e
                log_warn("record_coactivation failed: #{e.message}")
              end

              # Return the set of trace IDs associated with a given trace (bidirectional).
              def associations_for(trace_id)
                return [] unless db_ready?

                a_side = db[ASSOCIATIONS_TABLE]
                         .where(trace_id_a: trace_id)
                         .select_map(:trace_id_b)
                b_side = db[ASSOCIATIONS_TABLE]
                         .where(trace_id_b: trace_id)
                         .select_map(:trace_id_a)
                (a_side + b_side).uniq
              rescue StandardError => e
                log_warn("associations_for failed: #{e.message}")
                []
              end

              # BFS traversal starting from start_id.
              # Returns an array of { trace_id:, depth:, path: } hashes.
              def walk_associations(start_id:, max_hops: 12, min_strength: 0.1)
                return [] unless db_ready?

                start_row = traces_ds.where(trace_id: start_id).first
                return [] unless start_row

                results = []
                visited = Set.new([start_id])
                queue   = [[start_id, 0, [start_id]]]

                until queue.empty?
                  current_id, depth, path = queue.shift
                  neighbor_ids = associations_for(current_id)

                  neighbor_ids.each do |nid|
                    next if visited.include?(nid)

                    neighbor_row = traces_ds
                                   .where(trace_id: nid)
                                   .where { strength >= min_strength }
                                   .first
                    next unless neighbor_row

                    visited << nid
                    neighbor_path = path + [nid]
                    results << { trace_id: nid, depth: depth + 1, path: neighbor_path }
                    queue << [nid, depth + 1, neighbor_path] if depth + 1 < max_hops
                  end
                end

                results
              rescue StandardError => e
                log_warn("walk_associations failed: #{e.message}")
                []
              end

              # Delete the N traces with the lowest confidence for a given type (quota enforcement).
              def delete_lowest_confidence(trace_type:, count:)
                return unless db_ready?

                ids = traces_ds
                      .where(trace_type: trace_type.to_s)
                      .order(:confidence)
                      .limit(count)
                      .select_map(:trace_id)

                ids.each { |tid| delete(tid) }
              rescue StandardError => e
                log_warn("delete_lowest_confidence failed: #{e.message}")
              end

              # Delete the N least-recently-used traces for a given type (quota enforcement).
              def delete_least_recently_used(trace_type:, count:)
                return unless db_ready?

                ids = traces_ds
                      .where(trace_type: trace_type.to_s)
                      .order(:last_reinforced)
                      .limit(count)
                      .select_map(:trace_id)

                ids.each { |tid| delete(tid) }
              rescue StandardError => e
                log_warn("delete_least_recently_used failed: #{e.message}")
              end

              # Convenience: retrieve firmware-type traces.
              def firmware_traces
                retrieve_by_type(:firmware)
              end

              # No-op — this store is write-through; nothing to flush.
              def flush; end

              # Returns true when both required tables exist in the connected DB.
              def db_ready?
                defined?(Legion::Data) &&
                  Legion::Data.respond_to?(:connection) &&
                  Legion::Data.connection&.table_exists?(TRACES_TABLE) &&
                  Legion::Data.connection.table_exists?(ASSOCIATIONS_TABLE)
              rescue StandardError => _e
                false
              end

              private

              def db
                Legion::Data.connection
              end

              def resolve_agent_id
                Legion::Settings.dig(:agent, :id) || 'default'
              rescue StandardError => _e
                'default'
              end

              # Dataset for memory_traces scoped by tenant_id (if set).
              def traces_ds
                ds = db[TRACES_TABLE]
                @tenant_id ? ds.where(tenant_id: @tenant_id) : ds
              end

              def serialize_trace(trace)
                payload = trace[:content_payload] || trace[:content]
                tags    = trace[:domain_tags]
                assocs  = trace[:associated_traces]
                conf    = trace[:confidence]
                ev      = trace[:emotional_valence]

                {
                  trace_id:                trace[:trace_id],
                  agent_id:                @agent_id,
                  tenant_id:               @tenant_id,
                  trace_type:              sanitize_pg_string(trace[:trace_type].to_s),
                  content:                 sanitize_pg_string(payload.is_a?(Hash) ? Legion::JSON.dump(payload) : payload.to_s),
                  significance:            conf,
                  confidence:              conf,
                  associations:            sanitize_pg_string(assocs.is_a?(Array) ? Legion::JSON.dump(assocs) : '[]'),
                  domain_tags:             sanitize_pg_string(tags.is_a?(Array) ? Legion::JSON.dump(tags) : nil),
                  strength:                trace[:strength],
                  peak_strength:           trace[:peak_strength],
                  base_decay_rate:         trace[:base_decay_rate],
                  emotional_valence:       ev.is_a?(Numeric) ? ev.to_f : 0.0,
                  emotional_intensity:     trace[:emotional_intensity],
                  origin:                  sanitize_pg_string(trace[:origin].to_s),
                  source_agent_id:         sanitize_pg_string(trace[:source_agent_id]),
                  storage_tier:            sanitize_pg_string(trace[:storage_tier].to_s),
                  last_reinforced:         trace[:last_reinforced],
                  last_decayed:            trace[:last_decayed],
                  reinforcement_count:     trace[:reinforcement_count],
                  unresolved:              trace[:unresolved]              || false,
                  consolidation_candidate: trace[:consolidation_candidate] || false,
                  parent_trace_id:         sanitize_pg_string(trace[:parent_trace_id]),
                  encryption_key_id:       sanitize_pg_string(trace[:encryption_key_id]),
                  partition_id:            sanitize_pg_string(trace[:partition_id]),
                  created_at:              trace[:created_at] || Time.now.utc,
                  accessed_at:             Time.now.utc
                }
              end

              def deserialize_trace(row)
                content = parse_json_or_raw(row[:content])
                {
                  trace_id:                row[:trace_id],
                  trace_type:              row[:trace_type]&.to_sym,
                  content_payload:         content,
                  content:                 content,
                  strength:                row[:strength],
                  peak_strength:           row[:peak_strength],
                  base_decay_rate:         row[:base_decay_rate],
                  emotional_valence:       row[:emotional_valence].to_f,
                  emotional_intensity:     row[:emotional_intensity],
                  domain_tags:             parse_json_array(row[:domain_tags]),
                  origin:                  row[:origin]&.to_sym,
                  source_agent_id:         row[:source_agent_id],
                  created_at:              row[:created_at],
                  last_reinforced:         row[:last_reinforced],
                  last_decayed:            row[:last_decayed],
                  reinforcement_count:     row[:reinforcement_count],
                  confidence:              row[:confidence],
                  storage_tier:            row[:storage_tier]&.to_sym,
                  partition_id:            row[:partition_id],
                  encryption_key_id:       row[:encryption_key_id],
                  associated_traces:       parse_json_array(row[:associations]),
                  parent_trace_id:         row[:parent_trace_id],
                  child_trace_ids:         [],
                  unresolved:              row[:unresolved]              || false,
                  consolidation_candidate: row[:consolidation_candidate] || false
                }
              end

              # Map keyword fields for partial updates, translating to DB column names.
              def map_update_fields(fields)
                mapping = {
                  content_payload:   :content,
                  associated_traces: :associations,
                  parent_trace_id:   :parent_trace_id,
                  child_trace_ids:   nil # not stored as a column
                }

                fields.each_with_object({}) do |(k, v), row|
                  col = mapping.key?(k) ? mapping[k] : k
                  next if col.nil?

                  row[col] = case col
                             when :content
                               sanitize_pg_string(v.is_a?(Hash) ? Legion::JSON.dump(v) : v.to_s)
                             when :associations
                               sanitize_pg_string(v.is_a?(Array) ? Legion::JSON.dump(v) : '[]')
                             when :domain_tags
                               sanitize_pg_string(v.is_a?(Array) ? Legion::JSON.dump(v) : nil)
                             when :trace_type, :origin, :storage_tier
                               sanitize_pg_string(v.to_s)
                             else
                               v
                             end
                end
              end

              def parse_json_or_raw(raw)
                return raw unless raw.is_a?(String)

                parsed = Legion::JSON.load(raw)
                parsed.is_a?(Hash) ? parsed : raw
              rescue StandardError => _e
                raw
              end

              def parse_json_array(raw)
                return [] unless raw.is_a?(String)

                result = Legion::JSON.load(raw)
                result.is_a?(Array) ? result : []
              rescue StandardError => _e
                []
              end

              def sanitize_pg_string(value)
                return value unless value.is_a?(String)

                value.delete("\x00")
              end

              def log_warn(message)
                Legion::Logging.warn "[memory:postgres_store] #{message}"
              end
            end
          end
        end
      end
    end
  end
end
