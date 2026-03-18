# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module SemanticSatiation
          module Helpers
            module Constants
              MAX_CONCEPTS        = 300
              SATIATION_RATE      = 0.08
              RECOVERY_RATE       = 0.03
              SATIATION_THRESHOLD = 0.7
              DEFAULT_FLUENCY     = 1.0

              FLUENCY_LABELS = {
                (0.8..)     => :fluent,
                (0.6...0.8) => :normal,
                (0.4...0.6) => :reduced,
                (0.2...0.4) => :satiated,
                (..0.2)     => :meaningless
              }.freeze

              NOVELTY_LABELS = {
                (0.8..)     => :novel,
                (0.6...0.8) => :familiar,
                (0.4...0.6) => :routine,
                (0.2...0.4) => :overexposed,
                (..0.2)     => :saturated
              }.freeze
            end
          end
        end
      end
    end
  end
end
