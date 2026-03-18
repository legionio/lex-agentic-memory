# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Memory
        module SemanticSatiation
          module Helpers
            class Concept
              include Constants

              attr_reader :id, :label, :domain, :fluency, :exposure_count,
                          :last_exposed_at, :created_at

              def initialize(label:, domain: :general)
                @id             = SecureRandom.uuid
                @label          = label
                @domain         = domain
                @fluency        = DEFAULT_FLUENCY
                @exposure_count = 0
                @last_exposed_at = nil
                @created_at      = Time.now.utc
              end

              def expose!
                @exposure_count += 1
                @fluency = (@fluency - SATIATION_RATE).clamp(0.0, DEFAULT_FLUENCY).round(10)
                @last_exposed_at = Time.now.utc
              end

              def recover!(amount: RECOVERY_RATE)
                @fluency = (@fluency + amount).clamp(0.0, DEFAULT_FLUENCY).round(10)
              end

              def satiated?
                fluency < (DEFAULT_FLUENCY - SATIATION_THRESHOLD)
              end

              def fluency_label
                FLUENCY_LABELS.find { |range, _| range.cover?(fluency) }&.last || :meaningless
              end

              def novelty
                saturation = [exposure_count.to_f / 50.0, 1.0].min
                (DEFAULT_FLUENCY - saturation).clamp(0.0, DEFAULT_FLUENCY).round(10)
              end

              def novelty_label
                n = novelty
                NOVELTY_LABELS.find { |range, _| range.cover?(n) }&.last || :saturated
              end

              def time_since_exposure
                return nil unless last_exposed_at

                Time.now.utc - last_exposed_at
              end

              def to_h
                {
                  id:              id,
                  label:           label,
                  domain:          domain,
                  fluency:         fluency,
                  fluency_label:   fluency_label,
                  novelty:         novelty,
                  novelty_label:   novelty_label,
                  exposure_count:  exposure_count,
                  satiated:        satiated?,
                  last_exposed_at: last_exposed_at,
                  created_at:      created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
