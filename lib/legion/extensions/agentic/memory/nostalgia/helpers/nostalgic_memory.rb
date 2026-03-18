# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Nostalgia
          module Helpers
            class NostalgicMemory
              attr_reader :id, :content, :domain, :temporal_distance, :original_valence, :created_at

              def initialize(content:, domain: :unknown, warmth: Constants::DEFAULT_WARMTH,
                             original_valence: 0.5)
                @id               = ::SecureRandom.uuid
                @content          = content
                @domain           = normalize_domain(domain)
                @warmth           = warmth.clamp(0.0, Constants::WARMTH_CEILING)
                @original_valence = original_valence.clamp(0.0, 1.0)
                @current_valence  = @original_valence
                @temporal_distance = 0
                @created_at = Time.now.utc
              end

              def warmth
                @warmth.round(10)
              end

              def current_valence
                @current_valence.round(10)
              end

              def age!
                @temporal_distance += 1
                growth = Constants::WARMTH_GROWTH * temporal_distance_factor
                @warmth = (@warmth + growth).clamp(0.0, Constants::WARMTH_CEILING)
                self
              end

              def warm!(amount = Constants::WARMTH_GROWTH)
                factor = 1.0 + (temporal_distance / 100.0)
                @warmth = (@warmth + (amount.clamp(0.0, 1.0) * factor)).clamp(0.0, Constants::WARMTH_CEILING)
                @current_valence = [@current_valence + (amount * 0.5), 1.0].min.round(10)
                self
              end

              def cool!(amount = Constants::WARMTH_DECAY)
                @warmth = (@warmth - amount.clamp(0.0, 1.0)).clamp(0.0, Constants::WARMTH_CEILING)
                self
              end

              def rosy?
                warmth > @original_valence
              end

              def bittersweet?
                warmth >= Constants::BITTERSWEET_THRESHOLD && @original_valence < Constants::BITTERSWEET_THRESHOLD
              end

              def warmth_label
                Constants.label_for(Constants::WARMTH_LABELS, warmth)
              end

              def to_h
                {
                  id:                id,
                  content:           content,
                  domain:            domain,
                  warmth:            warmth,
                  warmth_label:      warmth_label,
                  temporal_distance: temporal_distance,
                  original_valence:  @original_valence,
                  current_valence:   current_valence,
                  rosy:              rosy?,
                  bittersweet:       bittersweet?,
                  created_at:        created_at
                }
              end

              private

              def normalize_domain(domain)
                sym = domain.to_sym
                Constants::MEMORY_DOMAINS.include?(sym) ? sym : :unknown
              end

              def temporal_distance_factor
                1.0 + (::Math.log(1 + @temporal_distance) * 0.1)
              end
            end
          end
        end
      end
    end
  end
end
