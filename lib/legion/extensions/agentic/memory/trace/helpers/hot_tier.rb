# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Trace
          module Helpers
            module HotTier
              HOT_TTL = 86_400 # 24 hours

              module_function

              # Cache a trace in the Redis hot tier.
              def cache_trace(trace, tenant_id: nil)
                return unless available?

                tid = tenant_id || trace[:partition_id]
                key = trace_key(tid, trace[:trace_id])
                data = serialize_trace(trace)
                Legion::Cache::RedisHash.hset(key, data)
                Legion::Cache::RedisHash.expire(key, HOT_TTL)

                index_key = "legion:tier:hot:#{tid}"
                Legion::Cache::RedisHash.zadd(index_key, Time.now.to_f, trace[:trace_id])
              end

              # Fetch a trace from the hot tier. Returns a deserialized trace hash or nil on miss.
              def fetch_trace(trace_id, tenant_id: nil)
                return nil unless available?

                key = trace_key(tenant_id, trace_id)
                data = Legion::Cache::RedisHash.hgetall(key)
                return nil if data.nil? || data.empty?

                deserialize_trace(data)
              end

              # Evict a trace from the hot tier and remove it from the sorted-set index.
              def evict_trace(trace_id, tenant_id: nil)
                return unless available?

                key = trace_key(tenant_id, trace_id)
                Legion::Cache.delete(key)

                index_key = "legion:tier:hot:#{tenant_id}"
                Legion::Cache::RedisHash.zrem(index_key, trace_id)
              end

              # Returns true when the RedisHash module is loaded and Redis is reachable.
              def available?
                defined?(Legion::Cache::RedisHash) &&
                  Legion::Cache::RedisHash.redis_available?
              rescue StandardError
                false
              end

              # Build the namespaced Redis key for a trace.
              def trace_key(tenant_id, trace_id)
                "legion:trace:#{tenant_id}:#{trace_id}"
              end

              # Serialize a trace hash to a string-only flat hash suitable for Redis HSET.
              def serialize_trace(trace)
                {
                  'trace_id'        => trace[:trace_id].to_s,
                  'trace_type'      => trace[:trace_type].to_s,
                  'content_payload' => trace[:content_payload].to_s,
                  'strength'        => trace[:strength].to_s,
                  'peak_strength'   => trace[:peak_strength].to_s,
                  'confidence'      => trace[:confidence].to_s,
                  'storage_tier'    => 'hot',
                  'partition_id'    => trace[:partition_id].to_s,
                  'last_reinforced' => (trace[:last_reinforced] || Time.now).to_s
                }
              end

              # Deserialize a Redis string-hash back to a typed trace hash.
              def deserialize_trace(data)
                {
                  trace_id:        data['trace_id'],
                  trace_type:      data['trace_type']&.to_sym,
                  content_payload: data['content_payload'],
                  strength:        data['strength']&.to_f,
                  peak_strength:   data['peak_strength']&.to_f,
                  confidence:      data['confidence']&.to_f,
                  storage_tier:    :hot,
                  partition_id:    data['partition_id'],
                  last_reinforced: data['last_reinforced']
                }
              end
            end
          end
        end
      end
    end
  end
end
