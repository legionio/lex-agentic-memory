# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Archaeology
          module Helpers
            class ExcavationSite
              include Constants

              attr_reader :id, :domain, :current_depth, :artifacts_found, :created_at

              alias started_at created_at

              def initialize(domain:)
                validate_domain!(domain)
                @id              = SecureRandom.uuid
                @domain          = domain.to_sym
                @current_depth   = :surface
                @artifacts_found = []
                @created_at      = Time.now.utc
              end

              def dig_deeper!
                idx = EXCAVATION_DEPTH_LEVELS.index(@current_depth) || 0
                return false if idx >= EXCAVATION_DEPTH_LEVELS.size - 1

                @current_depth = EXCAVATION_DEPTH_LEVELS[idx + 1]
                true
              end

              def complete?
                @current_depth == EXCAVATION_DEPTH_LEVELS.last
              end

              def excavate!
                weights  = DEPTH_RARITY_WEIGHTS.fetch(@current_depth, {})
                art_type = weighted_pick(weights)
                artifact = Artifact.new(type: art_type, domain: @domain,
                                        content: "#{art_type} from #{@current_depth}",
                                        depth_level: @current_depth,
                                        preservation: compute_base_preservation)
                @artifacts_found << artifact
                artifact
              end

              def survey
                {
                  id:              @id,
                  domain:          @domain,
                  current_depth:   @current_depth,
                  depth_label:     DEPTH_LABELS.fetch(@current_depth, 'Unknown'),
                  artifacts_count: @artifacts_found.size,
                  complete:        complete?,
                  started_at:      @created_at.iso8601
                }
              end

              def to_h
                survey.merge(artifacts: @artifacts_found.map(&:to_h))
              end

              private

              def validate_domain!(domain_val)
                return if DOMAIN_TYPES.include?(domain_val.to_sym)

                raise ArgumentError,
                      "unknown domain: #{domain_val.inspect}; " \
                      "must be one of #{DOMAIN_TYPES.inspect}"
              end

              def weighted_pick(weights)
                total = weights.values.sum
                return ARTIFACT_TYPES.sample if total.zero?

                roll       = rand(total)
                cumulative = 0
                weights.each do |type, weight|
                  cumulative += weight
                  return type if roll < cumulative
                end
                weights.keys.last
              end

              def compute_base_preservation
                mod = DEPTH_PRESERVATION_MODIFIER.fetch(@current_depth, 0.0)
                (DEFAULT_PRESERVATION + mod).clamp(0.0, 1.0)
              end
            end
          end
        end
      end
    end
  end
end
