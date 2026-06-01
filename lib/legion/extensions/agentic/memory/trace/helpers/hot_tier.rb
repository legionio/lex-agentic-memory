# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Trace
          module Helpers
            module HotTier
              HOT_TTL = 86_400 # 24 hours

              def self.log
                Legion::Logging
              end

              module_function

              # Cache a trace in the Redis hot tier.
              def cache_trace(trace, tenant_id: nil, agent_id: nil)
                return unless available?

                scope = cache_scope_id(trace, tenant_id: tenant_id, agent_id: agent_id)
                key = trace_key(scope, trace[:trace_id])
                data = serialize_trace(trace)
                Legion::Cache::RedisHash.hset(key, data)
                Legion::Cache::RedisHash.expire(key, HOT_TTL)

                index_key = "legion:tier:hot:#{scope}"
                Legion::Cache::RedisHash.zadd(index_key, Time.now.to_f, trace[:trace_id])
              end

              # Fetch a trace from the hot tier. Returns a deserialized trace hash or nil on miss.
              def fetch_trace(trace_id, tenant_id: nil, agent_id: nil)
                return nil unless available?

                key = trace_key(scope_id(tenant_id: tenant_id, agent_id: agent_id), trace_id)
                data = Legion::Cache::RedisHash.hgetall(key)
                return nil if data.nil? || data.empty?

                deserialize_trace(data)
              end

              # Evict a trace from the hot tier and remove it from the sorted-set index.
              def evict_trace(trace_id, tenant_id: nil, agent_id: nil)
                return unless available?

                scope = scope_id(tenant_id: tenant_id, agent_id: agent_id)
                key = trace_key(scope, trace_id)
                Legion::Cache.delete(key)

                index_key = "legion:tier:hot:#{scope}"
                Legion::Cache::RedisHash.zrem(index_key, trace_id)
              end

              # Returns true when the RedisHash module is loaded and Redis is reachable.
              def available?
                defined?(Legion::Cache::RedisHash) &&
                  Legion::Cache::RedisHash.redis_available?
              rescue StandardError => e
                log.error "[trace_persistence] hot_tier available?: #{e.message}"
                false
              end

              # Build the namespaced Redis key for a trace.
              def trace_key(scope_id, trace_id)
                "legion:trace:#{scope_id}:#{trace_id}"
              end

              def scope_id(tenant_id: nil, agent_id: nil)
                return tenant_id if tenant_id && agent_id.nil?
                return agent_id if agent_id && tenant_id.nil?

                [tenant_id, agent_id].compact.join(':')
              end

              def cache_scope_id(trace, tenant_id: nil, agent_id: nil)
                return scope_id(tenant_id: tenant_id, agent_id: agent_id) if agent_id
                return tenant_id if tenant_id

                trace[:partition_id]
              end

              # Serialize a trace hash to a string-only flat hash suitable for Redis HSET.
              # All fields are preserved as strings; arrays/hashes are JSON-encoded.
              def serialize_trace(trace)
                payload = trace[:content_payload] || trace[:content]
                {
                  'trace_id'                => trace[:trace_id].to_s,
                  'trace_type'              => trace[:trace_type].to_s,
                  'content_payload'         => payload.is_a?(Hash) || payload.is_a?(Array) ? Legion::JSON.dump(payload) : payload.to_s,
                  'strength'                => trace[:strength].to_s,
                  'peak_strength'           => trace[:peak_strength].to_s,
                  'base_decay_rate'         => trace[:base_decay_rate].to_s,
                  'confidence'              => trace[:confidence].to_s,
                  'emotional_valence'       => trace[:emotional_valence].to_s,
                  'emotional_intensity'     => trace[:emotional_intensity].to_s,
                  'storage_tier'            => 'hot',
                  'partition_id'            => trace[:partition_id].to_s,
                  'origin'                  => trace[:origin].to_s,
                  'source_agent_id'         => trace[:source_agent_id].to_s,
                  'encryption_key_id'       => trace[:encryption_key_id].to_s,
                  'parent_trace_id'         => trace[:parent_trace_id].to_s,
                  'domain_tags'             => trace[:domain_tags].is_a?(Array) ? Legion::JSON.dump(trace[:domain_tags]) : '[]',
                  'associated_traces'       => trace[:associated_traces].is_a?(Array) ? Legion::JSON.dump(trace[:associated_traces]) : '[]',
                  'child_trace_ids'         => trace[:child_trace_ids].is_a?(Array) ? Legion::JSON.dump(trace[:child_trace_ids]) : '[]',
                  'reinforcement_count'     => trace[:reinforcement_count].to_s,
                  'unresolved'              => trace[:unresolved].to_s,
                  'consolidation_candidate' => trace[:consolidation_candidate].to_s,
                  'last_reinforced'         => (trace[:last_reinforced] || Time.now).to_s,
                  'last_decayed'            => trace[:last_decayed].to_s,
                  'created_at'              => trace[:created_at].to_s
                }
              end

              # Deserialize a Redis string-hash back to a typed trace hash.
              def deserialize_trace(data)
                {
                  trace_id:                data['trace_id'],
                  trace_type:              data['trace_type']&.to_sym,
                  content_payload:         parse_json_or_string(data['content_payload']),
                  content:                 parse_json_or_string(data['content_payload']),
                  strength:                data['strength']&.to_f,
                  peak_strength:           data['peak_strength']&.to_f,
                  base_decay_rate:         data['base_decay_rate']&.to_f,
                  confidence:              data['confidence']&.to_f,
                  emotional_valence:       data['emotional_valence'].to_f,
                  emotional_intensity:     data['emotional_intensity'].to_f,
                  storage_tier:            :hot,
                  partition_id:            presence(data['partition_id']),
                  origin:                  presence(data['origin'])&.to_sym,
                  source_agent_id:         presence(data['source_agent_id']),
                  encryption_key_id:       presence(data['encryption_key_id']),
                  parent_trace_id:         presence(data['parent_trace_id']),
                  domain_tags:             parse_json_array(data['domain_tags']),
                  associated_traces:       parse_json_array(data['associated_traces']),
                  child_trace_ids:         parse_json_array(data['child_trace_ids']),
                  reinforcement_count:     data['reinforcement_count'].to_i,
                  unresolved:              data['unresolved'] == 'true',
                  consolidation_candidate: data['consolidation_candidate'] == 'true',
                  last_reinforced:         data['last_reinforced'],
                  last_decayed:            presence(data['last_decayed']),
                  created_at:              presence(data['created_at'])
                }
              end

              # Parse a JSON array string safely; returns [] on failure.
              def parse_json_array(raw)
                return [] if raw.nil? || !raw.is_a?(String) || raw.strip.empty?

                parsed = Legion::JSON.load(raw)
                parsed.is_a?(Array) ? parsed : []
              rescue StandardError => e
                log.debug "[trace_persistence] parse_json_array: #{e.message}"
                []
              end

              # Attempt to parse JSON, fall back to raw string.
              def parse_json_or_string(raw)
                return raw unless raw.is_a?(String)

                stripped = raw.strip
                return raw unless (stripped.start_with?('{') && stripped.end_with?('}')) ||
                                  (stripped.start_with?('[') && stripped.end_with?(']'))

                parsed = Legion::JSON.load(stripped)
                parsed.is_a?(Hash) || parsed.is_a?(Array) ? parsed : raw
              rescue StandardError => e
                log.debug "[trace_persistence] parse_json_or_string: #{e.message}"
                raw
              end

              # Return value only if it is a non-empty string.
              def presence(value)
                return nil unless value.is_a?(String)

                stripped = value.strip
                stripped.empty? ? nil : stripped
              end
            end
          end
        end
      end
    end
  end
end
