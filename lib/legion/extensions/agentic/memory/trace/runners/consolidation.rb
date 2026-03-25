# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Trace
          module Runners
            module Consolidation
              def reinforce(trace_id:, store: nil, imprint_active: false, **)
                store ||= default_store
                trace = store.get(trace_id)
                return { found: false } unless trace
                return { found: true, reinforced: false, reason: :firmware } if trace[:trace_type] == :firmware

                new_strength = Helpers::Decay.compute_reinforcement(
                  current_strength: trace[:strength], imprint_active: imprint_active
                )

                now = Time.now.utc
                trace[:strength] = new_strength
                trace[:peak_strength] = [trace[:peak_strength], new_strength].max
                trace[:last_reinforced] = now
                trace[:reinforcement_count] += 1

                store.store(trace)

                Legion::Logging.debug "[memory] reinforced #{trace_id[0..7]} strength=#{new_strength.round(3)}#{' (imprint 3x)' if imprint_active}"
                { found: true, reinforced: true, trace_id: trace_id, new_strength: new_strength }
              end

              def decay_cycle(store: nil, tick_count: 1, **)
                store ||= default_store
                decayed = 0
                pruned = 0

                store.all_traces.each do |trace|
                  next if trace[:base_decay_rate].zero?

                  new_strength = Helpers::Decay.compute_decay(
                    peak_strength:       trace[:peak_strength],
                    base_decay_rate:     trace[:base_decay_rate],
                    ticks_since_access:  tick_count,
                    emotional_intensity: trace[:emotional_intensity]
                  )

                  if new_strength <= Helpers::Trace::PRUNE_THRESHOLD
                    store.delete(trace[:trace_id])
                    pruned += 1
                  else
                    trace[:strength] = new_strength
                    trace[:last_decayed] = Time.now.utc
                    store.store(trace)
                    decayed += 1
                  end
                end

                Legion::Logging.debug "[memory] decay cycle: decayed=#{decayed} pruned=#{pruned}"
                { decayed: decayed, pruned: pruned }
              end

              def migrate_tier(store: nil, **)
                store ||= default_store
                migrated = 0
                now = Time.now.utc

                store.all_traces.each do |trace|
                  new_tier = Helpers::Decay.compute_storage_tier(trace: trace, now: now)
                  next if trace[:storage_tier] == new_tier

                  trace[:storage_tier] = new_tier
                  store.store(trace)
                  migrated += 1
                end

                Legion::Logging.debug "[memory] tier migration: migrated=#{migrated}"
                { migrated: migrated }
              end

              def hebbian_link(trace_id_a: nil, trace_id_b: nil, store: nil, **)
                return { linked: false, reason: :missing_trace_ids } if trace_id_a.nil? || trace_id_b.nil?

                store ||= default_store
                store.record_coactivation(trace_id_a, trace_id_b)
                Legion::Logging.debug "[memory] hebbian link #{trace_id_a[0..7]} <-> #{trace_id_b[0..7]}"
                { linked: true }
              end

              def enforce_quota(store: nil, **)
                store ||= default_store
                quota = Quota.new
                quota.enforce!(store)
                { success: true, within_limits: quota.within_limits?(store) }
              end

              def erase_by_type(type:, store: nil, **)
                store ||= default_store
                type = type.to_sym
                traces = store.retrieve_by_type(type, min_strength: 0.0, limit: 100_000)
                count = traces.size
                traces.each { |t| store.delete(t[:trace_id]) }
                Legion::Logging.info "[memory] erased #{count} traces of type=#{type}"
                { erased: count, type: type }
              end

              def erase_by_agent(partition_id:, store: nil, **)
                store ||= default_store
                traces = store.all_traces.select { |t| t[:partition_id] == partition_id }
                count = traces.size
                traces.each { |t| store.delete(t[:trace_id]) }
                Legion::Logging.info "[memory] erased #{count} traces for partition=#{partition_id}"
                { erased: count, partition_id: partition_id }
              end

              private

              def default_store
                @default_store ||= Legion::Extensions::Agentic::Memory::Trace.shared_store
              end

              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)
            end
          end
        end
      end
    end
  end
end
