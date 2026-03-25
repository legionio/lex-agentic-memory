# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Hologram
          module Helpers
            module Constants
              # Resolution levels for holographic recall quality
              RESOLUTION_LEVELS = %i[perfect high medium low fragmentary].freeze

              # Maximum number of holograms retained in the engine
              MAX_HOLOGRAMS = 100

              # Per-cycle decay applied to fragment fidelity
              INTERFERENCE_DECAY = 0.03

              # Minimum completeness for a fragment to contribute to reconstruction
              RECONSTRUCTION_THRESHOLD = 0.3

              # Fragment labels based on completeness range
              FRAGMENT_LABELS = [
                [(0.9..),       :intact],
                [(0.7...0.9),   :substantial],
                [(0.5...0.7),   :partial],
                [(0.3...0.5),   :degraded],
                [..0.3,         :fragmentary]
              ].freeze

              # Resolution labels mapping hologram resolution to symbol
              RESOLUTION_LABELS = [
                [(0.9..),       :perfect],
                [(0.7...0.9),   :high],
                [(0.5...0.7),   :medium],
                [(0.3...0.5),   :low],
                [..0.3,         :fragmentary]
              ].freeze

              # Fidelity labels for individual fragments
              FIDELITY_LABELS = [
                [(0.8..),       :pristine],
                [(0.6...0.8),   :clear],
                [(0.4...0.6),   :hazy],
                [(0.2...0.4),   :clouded],
                [..0.2,         :corrupted]
              ].freeze

              # Interference strength labels
              INTERFERENCE_LABELS = [
                [(0.7..),       :strong],
                [(0.4...0.7),   :moderate],
                [(0.1...0.4),   :weak],
                [..0.1,         :negligible]
              ].freeze

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
