# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Nostalgia
          module Helpers
            class NostalgiaEvent
              attr_reader :id, :memory_id, :trigger, :intensity, :effect_on_mood, :occurred_at

              def initialize(memory_id:, trigger:, intensity:, effect_on_mood: 0.0)
                @id            = ::SecureRandom.uuid
                @memory_id     = memory_id
                @trigger       = trigger
                @intensity     = intensity.clamp(0.0, 1.0)
                @effect_on_mood = effect_on_mood.clamp(-1.0, 1.0)
                @occurred_at = Time.now.utc
              end

              def nostalgia_label
                Constants.label_for(Constants::NOSTALGIA_LABELS, @intensity)
              end

              def to_h
                {
                  id:              id,
                  memory_id:       memory_id,
                  trigger:         trigger,
                  intensity:       @intensity,
                  nostalgia_label: nostalgia_label,
                  effect_on_mood:  @effect_on_mood,
                  occurred_at:     occurred_at
                }
              end
            end
          end
        end
      end
    end
  end
end
