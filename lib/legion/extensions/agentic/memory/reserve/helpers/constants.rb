# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Reserve
          module Helpers
            module Constants
              # Maximum tracked pathways
              MAX_PATHWAYS = 100

              # Maximum tracked compensations
              MAX_COMPENSATIONS = 200

              # Maximum event history
              MAX_HISTORY = 300

              # Default pathway capacity (0..1)
              DEFAULT_CAPACITY = 1.0

              # Capacity bounds
              CAPACITY_FLOOR   = 0.0
              CAPACITY_CEILING = 1.0

              # Threshold below which a pathway is considered degraded
              DEGRADED_THRESHOLD = 0.5

              # Threshold below which a pathway is considered failed
              FAILED_THRESHOLD = 0.1

              # Compensation efficiency — how much of lost capacity a backup restores
              COMPENSATION_EFFICIENCY = 0.7

              # Recovery rate per tick
              RECOVERY_RATE = 0.02

              # Decay rate for unused compensatory pathways
              COMPENSATION_DECAY = 0.01

              # Reserve levels based on overall reserve ratio
              RESERVE_LABELS = {
                (0.8..)     => :robust,
                (0.6...0.8) => :adequate,
                (0.4...0.6) => :reduced,
                (0.2...0.4) => :vulnerable,
                (..0.2)     => :critical
              }.freeze

              # Pathway states
              PATHWAY_STATES = %i[healthy degraded compensating failed].freeze
            end
          end
        end
      end
    end
  end
end
