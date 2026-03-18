# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Echo
          module Helpers
            module Constants
              MAX_ECHOES        = 300
              MAX_INTERACTIONS  = 500
              DEFAULT_INTENSITY = 0.8
              ECHO_DECAY        = 0.1
              REINFORCEMENT     = 0.15
              INTERFERENCE_THRESHOLD = 0.4
              PRIMING_THRESHOLD = 0.3
              SILENT_THRESHOLD  = 0.05

              ECHO_TYPES = %i[
                thought emotion decision observation
                prediction error success failure
              ].freeze

              INTENSITY_LABELS = {
                (0.8..)     => :reverberating,
                (0.6...0.8) => :strong,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :fading,
                (..0.2)     => :whisper
              }.freeze

              EFFECT_LABELS = {
                (0.6..)     => :dominant,
                (0.3...0.6) => :influential,
                (0.1...0.3) => :subtle,
                (..0.1)     => :negligible
              }.freeze

              CHAMBER_LABELS = {
                (0.8..)     => :echo_chamber,
                (0.6...0.8) => :resonant,
                (0.4...0.6) => :balanced,
                (0.2...0.4) => :diverse,
                (..0.2)     => :scattered
              }.freeze

              def self.label_for(labels, value)
                match = labels.find { |range, _| range.cover?(value) }
                match&.last
              end
            end
          end
        end
      end
    end
  end
end
