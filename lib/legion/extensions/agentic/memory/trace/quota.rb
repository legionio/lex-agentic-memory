# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Trace
          class Quota
            DEFAULTS = {
              max_traces: 10_000,
              max_bytes:  52_428_800, # 50MB
              eviction:   :lru
            }.freeze

            attr_reader :max_traces, :max_bytes, :eviction

            def initialize(**opts)
              config = DEFAULTS.merge(opts)
              @max_traces = config[:max_traces]
              @max_bytes = config[:max_bytes]
              @eviction = config[:eviction].to_sym
            end

            def enforce!(store)
              evict_count = store.count - max_traces
              evict!(store, evict_count) if evict_count.positive?

              return unless store.respond_to?(:total_bytes)

              overage = store.total_bytes - max_bytes
              evict!(store, estimate_eviction_count(overage)) if overage.positive?
            end

            def within_limits?(store)
              return store.count <= max_traces unless store.respond_to?(:total_bytes)

              store.count <= max_traces && store.total_bytes <= max_bytes
            end

            private

            def evict!(store, count)
              return if count <= 0

              case eviction
              when :lru
                return unless store.respond_to?(:delete_least_recently_used)

                store.delete_least_recently_used(count: count)
              when :lowest_confidence
                return unless store.respond_to?(:delete_lowest_confidence)

                store.delete_lowest_confidence(count: count)
              end
            end

            def estimate_eviction_count(overage_bytes)
              [(overage_bytes / 1024.0 * 10).ceil, 1].max
            end
          end
        end
      end
    end
  end
end
