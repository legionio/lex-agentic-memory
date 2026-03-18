# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Paleontology
          module Helpers
            module Constants
              MAX_FOSSILS      = 500
              MAX_STRATA       = 20
              MAX_EXCAVATIONS  = 100
              FOSSILIZATION_RATE = 0.02
              MIN_FOSSIL_AGE = 300

              FOSSIL_TYPES = %i[
                strategy pattern belief heuristic
                association routine assumption framework
              ].freeze

              EXTINCTION_CAUSES = %i[
                obsolescence contradiction displacement
                energy_cost irrelevance environmental_shift
              ].freeze

              ERA_NAMES = %i[
                primordial archaic classical medieval
                renaissance industrial modern contemporary
              ].freeze

              PRESERVATION_STATES = %i[
                pristine mineralized fragmented trace imprint
              ].freeze

              PRESERVATION_LABELS = [
                [0.8..1.0, :pristine],
                [0.6..0.8, :mineralized],
                [0.4..0.6, :fragmented],
                [0.2..0.4, :trace],
                [0.0..0.2, :imprint]
              ].freeze

              SIGNIFICANCE_LABELS = [
                [0.8..1.0, :keystone],
                [0.6..0.8, :significant],
                [0.4..0.6, :notable],
                [0.2..0.4, :minor],
                [0.0..0.2, :trivial]
              ].freeze

              STRATUM_LABELS = {
                0 => 'Surface (contemporary)',
                1 => 'Shallow (recent history)',
                2 => 'Mid (established patterns)',
                3 => 'Deep (foundational layers)',
                4 => 'Bedrock (primordial cognition)'
              }.freeze

              def self.label_for(table, value)
                table.each { |range, label| return label if range.cover?(value) }
                table.last.last
              end
            end
          end
        end
      end
    end
  end
end
