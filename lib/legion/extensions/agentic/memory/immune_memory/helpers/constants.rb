# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module ImmuneMemory
          module Helpers
            module Constants
              MAX_MEMORY_CELLS = 500
              MAX_ENCOUNTERS = 1000
              MAX_ANTIBODY_LIBRARY = 300

              # T-cell parameters (cell-mediated: direct threat neutralization)
              T_CELL_ACTIVATION_THRESHOLD = 0.4
              T_CELL_BOOST = 0.12
              T_CELL_DECAY = 0.01
              T_CELL_LIFESPAN = 100 # decay cycles before expiry check

              # B-cell parameters (humoral: antibody production)
              B_CELL_ACTIVATION_THRESHOLD = 0.3
              B_CELL_BOOST = 0.1
              B_CELL_DECAY = 0.008
              B_CELL_ANTIBODY_PRODUCTION = 0.15

              # Secondary response amplification
              PRIMARY_RESPONSE_SPEED = 1.0
              SECONDARY_RESPONSE_SPEED = 3.0
              MEMORY_RECOGNITION_THRESHOLD = 0.6

              # Vaccination (pre-exposure)
              VACCINATION_STRENGTH = 0.5

              THREAT_TYPES = %i[
                prompt_injection data_poisoning social_engineering
                resource_exhaustion privilege_escalation information_leak
                logic_manipulation identity_spoofing
              ].freeze

              CELL_TYPES = %i[t_helper t_killer b_memory b_plasma].freeze

              IMMUNITY_LABELS = {
                (0.8..)     => :immune,
                (0.6...0.8) => :resistant,
                (0.4...0.6) => :partial,
                (0.2...0.4) => :vulnerable,
                (..0.2)     => :naive
              }.freeze

              RESPONSE_SPEED_LABELS = {
                (2.5..)     => :lightning,
                (1.8...2.5) => :rapid,
                (1.0...1.8) => :normal,
                (0.5...1.0) => :slow,
                (..0.5)     => :impaired
              }.freeze

              HEALTH_LABELS = {
                (0.8..)     => :robust,
                (0.6...0.8) => :healthy,
                (0.4...0.6) => :adequate,
                (0.2...0.4) => :weakened,
                (..0.2)     => :compromised
              }.freeze

              MATURITY_LABELS = {
                (0.8..)     => :veteran,
                (0.6...0.8) => :experienced,
                (0.4...0.6) => :developing,
                (0.2...0.4) => :immature,
                (..0.2)     => :naive
              }.freeze

              def self.label_for(labels, value)
                labels.each { |range, label| return label if range.cover?(value) }
                :unknown
              end
            end
          end
        end
      end
    end
  end
end
