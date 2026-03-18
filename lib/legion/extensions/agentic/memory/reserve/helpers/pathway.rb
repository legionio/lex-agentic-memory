# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Reserve
          module Helpers
            class Pathway
              include Constants

              attr_reader :id, :domain, :function, :capacity, :backup_ids,
                          :damage_count, :compensation_count, :created_at, :updated_at

              def initialize(id:, function:, domain: :general, capacity: DEFAULT_CAPACITY)
                @id                 = id
                @function           = function
                @domain             = domain
                @capacity           = capacity.clamp(CAPACITY_FLOOR, CAPACITY_CEILING)
                @backup_ids         = []
                @damage_count       = 0
                @compensation_count = 0
                @created_at         = Time.now.utc
                @updated_at         = @created_at
              end

              def damage(amount:)
                @capacity = (@capacity - amount.abs).clamp(CAPACITY_FLOOR, CAPACITY_CEILING)
                @damage_count += 1
                @updated_at = Time.now.utc
                self
              end

              def recover(amount: RECOVERY_RATE)
                @capacity = (@capacity + amount.abs).clamp(CAPACITY_FLOOR, CAPACITY_CEILING)
                @updated_at = Time.now.utc
                self
              end

              def add_backup(pathway_id:)
                return self if @backup_ids.include?(pathway_id)

                @backup_ids << pathway_id
                @updated_at = Time.now.utc
                self
              end

              def remove_backup(pathway_id:)
                @backup_ids.delete(pathway_id)
                @updated_at = Time.now.utc
                self
              end

              def compensate!
                @compensation_count += 1
                @updated_at = Time.now.utc
              end

              def state
                return :failed if @capacity <= FAILED_THRESHOLD
                return :compensating if @capacity <= DEGRADED_THRESHOLD && !@backup_ids.empty?
                return :degraded if @capacity <= DEGRADED_THRESHOLD

                :healthy
              end

              def healthy?
                state == :healthy
              end

              def degraded?
                @capacity <= DEGRADED_THRESHOLD
              end

              def failed?
                @capacity <= FAILED_THRESHOLD
              end

              def effective_capacity(backup_capacities: [])
                return @capacity if @capacity > DEGRADED_THRESHOLD || backup_capacities.empty?

                deficit = DEGRADED_THRESHOLD - @capacity
                compensation = backup_capacities.sum(0.0) * COMPENSATION_EFFICIENCY
                (@capacity + [compensation, deficit].min).clamp(CAPACITY_FLOOR, CAPACITY_CEILING)
              end

              def redundancy
                @backup_ids.size
              end

              def to_h
                {
                  id:                 @id,
                  function:           @function,
                  domain:             @domain,
                  capacity:           @capacity.round(4),
                  state:              state,
                  backup_count:       @backup_ids.size,
                  backup_ids:         @backup_ids.dup,
                  damage_count:       @damage_count,
                  compensation_count: @compensation_count,
                  created_at:         @created_at,
                  updated_at:         @updated_at
                }
              end
            end
          end
        end
      end
    end
  end
end
