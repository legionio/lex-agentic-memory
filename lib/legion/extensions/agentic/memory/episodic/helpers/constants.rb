# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Episodic
          module Helpers
            module Constants
              MAX_EPISODES             = 30
              MAX_BINDINGS_PER_EPISODE = 10
              MAX_HISTORY              = 200
              EPISODE_TTL              = 120
              BINDING_STRENGTH_FLOOR   = 0.05
              BINDING_DECAY            = 0.015
              DEFAULT_BINDING_STRENGTH = 0.5
              ATTENTION_BOOST          = 0.2
              REHEARSAL_BOOST          = 0.15
              INTEGRATION_THRESHOLD    = 0.4
              RECENTLY_ACCESSED_WINDOW = 30

              MODALITIES = %i[verbal visual spatial semantic emotional procedural temporal].freeze

              COHERENCE_LABELS = {
                (0.0...0.3)  => :fragmented,
                (0.3...0.6)  => :partial,
                (0.6...0.85) => :coherent,
                (0.85..1.0)  => :vivid
              }.freeze
            end
          end
        end
      end
    end
  end
end
