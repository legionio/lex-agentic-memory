# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Memory
        module EchoChamber
          module Helpers
            class Echo
              include Constants

              attr_reader :id, :content, :echo_type, :domain, :source_agent,
                          :amplitude, :frequency, :original_amplitude, :created_at

              def initialize(content:, echo_type: :belief, domain: :general,
                             source_agent: nil, amplitude: DEFAULT_AMPLITUDE)
                @id               = SecureRandom.uuid
                @content          = content
                @echo_type        = validate_type(echo_type)
                @domain           = domain.to_sym
                @source_agent     = source_agent
                @amplitude        = amplitude.to_f.clamp(0.0, 1.0).round(10)
                @original_amplitude = @amplitude
                @frequency        = 1
                @created_at       = Time.now.utc
              end

              def amplify!(rate = AMPLIFICATION_RATE)
                @frequency += 1
                @amplitude = (@amplitude + rate).clamp(0.0, 1.0).round(10)
                self
              end

              def dampen!(rate = DECAY_RATE)
                @amplitude = (@amplitude - rate).clamp(0.0, 1.0).round(10)
                self
              end

              def resonate?
                @amplitude >= DISRUPTION_THRESHOLD
              end

              def fading?
                @amplitude <= POROUS_THRESHOLD
              end

              def silent?
                @amplitude <= SILENT_THRESHOLD
              end

              def frequency_label
                Constants.label_for(RESONANCE_LABELS, frequency_score)
              end

              def amplitude_label
                Constants.label_for(AMPLIFICATION_LABELS, @amplitude)
              end

              def to_h
                {
                  id:                 @id,
                  content:            @content,
                  echo_type:          @echo_type,
                  domain:             @domain,
                  source_agent:       @source_agent,
                  amplitude:          @amplitude,
                  original_amplitude: @original_amplitude,
                  frequency:          @frequency,
                  frequency_label:    frequency_label,
                  amplitude_label:    amplitude_label,
                  resonate:           resonate?,
                  fading:             fading?,
                  silent:             silent?,
                  created_at:         @created_at
                }
              end

              private

              def validate_type(type)
                sym = type.to_sym
                ECHO_TYPES.include?(sym) ? sym : :belief
              end

              def frequency_score
                [@frequency.to_f / 20.0, 1.0].min.round(10)
              end
            end
          end
        end
      end
    end
  end
end
