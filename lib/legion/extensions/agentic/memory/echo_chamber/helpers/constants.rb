# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module EchoChamber
          module Helpers
            module Constants
              MAX_ECHOES             = 500
              MAX_CHAMBERS           = 50
              AMPLIFICATION_RATE     = 0.1
              DECAY_RATE             = 0.02
              DISRUPTION_THRESHOLD   = 0.7
              SEALED_THRESHOLD       = 0.8
              POROUS_THRESHOLD       = 0.3
              BREAKTHROUGH_BONUS     = 0.15
              SILENT_THRESHOLD       = 0.05
              DEFAULT_AMPLITUDE      = 0.5
              DEFAULT_WALL_THICKNESS = 0.5

              ECHO_TYPES = %i[belief assumption bias hypothesis conviction].freeze

              CHAMBER_STATES = %i[forming resonating saturated disrupted collapsed].freeze

              RESONANCE_LABELS = {
                (0.8..)     => :thunderous,
                (0.6...0.8) => :resonant,
                (0.4...0.6) => :humming,
                (0.2...0.4) => :fading,
                (..0.2)     => :silent
              }.freeze

              AMPLIFICATION_LABELS = {
                (0.8..)     => :deafening,
                (0.6...0.8) => :loud,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :quiet,
                (..0.2)     => :muted
              }.freeze

              CHAMBER_STATE_LABELS = {
                forming:    'Chamber is newly formed, echoes still accumulating',
                resonating: 'Chamber is actively reinforcing beliefs',
                saturated:  'Chamber has reached maximum self-reinforcement',
                disrupted:  'External input has broken through the chamber walls',
                collapsed:  'Chamber has lost coherence and dissolved'
              }.freeze

              def self.label_for(table, value)
                match = table.find { |range, _| range.cover?(value) }
                match&.last
              end
            end
          end
        end
      end
    end
  end
end
