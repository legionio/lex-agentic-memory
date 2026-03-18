# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Palimpsest
          module Helpers
            module Constants
              MAX_PALIMPSESTS       = 200
              MAX_LAYERS_PER_TOPIC  = 20
              DEFAULT_CONFIDENCE    = 0.7
              GHOST_THRESHOLD       = 0.1
              EROSION_RATE          = 0.05
              GHOST_DECAY           = 0.02

              LAYER_DOMAINS = %i[
                factual procedural normative identity
                relational emotional strategic unknown
              ].freeze

              CONFIDENCE_LABELS = {
                (0.9..)     => :certain,
                (0.7...0.9) => :high,
                (0.5...0.7) => :moderate,
                (0.3...0.5) => :low,
                (0.1...0.3) => :faint,
                (..0.1)     => :ghost
              }.freeze

              GHOST_LABELS = {
                (0.5..)     => :strong_ghost,
                (0.3...0.5) => :moderate_ghost,
                (0.1...0.3) => :faint_ghost,
                (..0.1)     => :dissipated
              }.freeze

              DRIFT_LABELS = {
                (0.7..)      => :radical,
                (0.4...0.7)  => :major,
                (0.2...0.4)  => :moderate,
                (0.05...0.2) => :minor,
                (..0.05)     => :stable
              }.freeze

              def self.label_for(labels_hash, value)
                labels_hash.each { |range, label| return label if range.cover?(value) }
                labels_hash.values.last
              end
            end
          end
        end
      end
    end
  end
end
