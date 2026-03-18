# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Episodic
          module Helpers
            class EpisodicBinding
              include Constants

              attr_reader :id, :modality, :content, :source, :strength

              def initialize(modality:, content:, source:, strength: DEFAULT_BINDING_STRENGTH)
                raise ArgumentError, "invalid modality: #{modality}" unless MODALITIES.include?(modality.to_sym)

                @id       = SecureRandom.uuid
                @modality = modality.to_sym
                @content  = content
                @source   = source.to_sym
                @strength = strength.to_f.clamp(0.0, 1.0)
              end

              def decay
                @strength = [@strength - BINDING_DECAY, 0.0].max
              end

              def strengthen(amount)
                @strength = [@strength + amount.to_f, 1.0].min
              end

              def integrated?
                @strength >= INTEGRATION_THRESHOLD
              end

              def faded?
                @strength <= BINDING_STRENGTH_FLOOR
              end

              def to_h
                {
                  id:       @id,
                  modality: @modality,
                  content:  @content,
                  source:   @source,
                  strength: @strength
                }
              end
            end
          end
        end
      end
    end
  end
end
