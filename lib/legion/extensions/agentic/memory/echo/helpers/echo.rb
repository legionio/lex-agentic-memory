# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Echo
          module Helpers
            class Echo
              include Constants

              attr_reader :id, :content, :echo_type, :domain, :intensity,
                          :original_intensity, :decay_count, :created_at

              def initialize(content:, echo_type: :thought, domain: :general, intensity: DEFAULT_INTENSITY)
                @id                 = SecureRandom.uuid
                @content            = content
                @echo_type          = validate_type(echo_type)
                @domain             = domain.to_sym
                @intensity          = intensity.to_f.clamp(0.0, 1.0).round(10)
                @original_intensity = @intensity
                @decay_count        = 0
                @created_at         = Time.now.utc
              end

              def decay!
                @decay_count += 1
                @intensity = (@intensity - ECHO_DECAY).clamp(0.0, 1.0).round(10)
                self
              end

              def reinforce!(amount = REINFORCEMENT)
                @intensity = (@intensity + amount).clamp(0.0, 1.0).round(10)
                self
              end

              def silent?
                @intensity <= SILENT_THRESHOLD
              end

              def active?
                @intensity > SILENT_THRESHOLD
              end

              def priming?
                @intensity >= PRIMING_THRESHOLD
              end

              def interfering?
                @intensity >= INTERFERENCE_THRESHOLD
              end

              def persistence
                return 0.0 if @original_intensity.zero?

                (@intensity / @original_intensity).clamp(0.0, 1.0).round(10)
              end

              def intensity_label = Constants.label_for(INTENSITY_LABELS, @intensity)
              def effect_label = Constants.label_for(EFFECT_LABELS, @intensity)

              def to_h
                {
                  id:                 @id,
                  content:            @content,
                  echo_type:          @echo_type,
                  domain:             @domain,
                  intensity:          @intensity,
                  original_intensity: @original_intensity,
                  intensity_label:    intensity_label,
                  effect_label:       effect_label,
                  priming:            priming?,
                  interfering:        interfering?,
                  silent:             silent?,
                  persistence:        persistence,
                  decay_count:        @decay_count,
                  created_at:         @created_at
                }
              end

              private

              def validate_type(type)
                sym = type.to_sym
                ECHO_TYPES.include?(sym) ? sym : :thought
              end
            end
          end
        end
      end
    end
  end
end
