# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Paleontology
          module Helpers
            class Fossil
              attr_reader :id, :fossil_type, :domain, :content,
                          :extinction_cause, :era, :stratum_depth,
                          :discovered_at, :extinct_at, :lineage_ids
              attr_accessor :preservation, :significance

              def initialize(fossil_type:, domain:, content:, extinction_cause:,
                             era: nil, stratum_depth: 0, preservation: nil,
                             significance: nil)
                validate_type!(fossil_type)
                validate_cause!(extinction_cause)
                assign_core(fossil_type, domain, content, extinction_cause)
                assign_metadata(era, stratum_depth, preservation, significance)
              end

              def erode!(rate: Constants::FOSSILIZATION_RATE)
                @preservation = (@preservation - rate.abs).clamp(0.0, 1.0).round(10)
                self
              end

              def reinforce!(boost: 0.1)
                @significance = (@significance + boost.abs).clamp(0.0, 1.0).round(10)
                self
              end

              def imprint?
                @preservation < 0.2
              end

              def keystone?
                @significance >= 0.8
              end

              def ancient?
                (Time.now.utc - @extinct_at) > 5_000_000
              end

              def preservation_label
                Constants.label_for(Constants::PRESERVATION_LABELS, @preservation)
              end

              def significance_label
                Constants.label_for(Constants::SIGNIFICANCE_LABELS, @significance)
              end

              def link_lineage(other_id)
                @lineage_ids << other_id unless @lineage_ids.include?(other_id)
              end

              def to_h
                {
                  id:                 @id,
                  fossil_type:        @fossil_type,
                  domain:             @domain,
                  content:            @content,
                  extinction_cause:   @extinction_cause,
                  era:                @era,
                  stratum_depth:      @stratum_depth,
                  preservation:       @preservation,
                  preservation_label: preservation_label,
                  significance:       @significance,
                  significance_label: significance_label,
                  discovered_at:      @discovered_at,
                  extinct_at:         @extinct_at,
                  lineage_ids:        @lineage_ids,
                  imprint:            imprint?,
                  keystone:           keystone?,
                  ancient:            ancient?
                }
              end

              private

              def assign_core(fossil_type, domain, content, extinction_cause)
                @id               = SecureRandom.uuid
                @fossil_type      = fossil_type.to_sym
                @domain           = domain.to_sym
                @content          = content.to_s
                @extinction_cause = extinction_cause.to_sym
              end

              def assign_metadata(era, stratum_depth, preservation, significance)
                @era           = (era || assign_era(stratum_depth)).to_sym
                @stratum_depth = stratum_depth.to_i.clamp(0, 4)
                @preservation  = (preservation || 0.8).to_f.clamp(0.0, 1.0).round(10)
                @significance  = (significance || 0.5).to_f.clamp(0.0, 1.0).round(10)
                @discovered_at = Time.now.utc
                @extinct_at    = Time.now.utc - rand(100..10_000_000)
                @lineage_ids   = []
              end

              def validate_type!(val)
                return if Constants::FOSSIL_TYPES.include?(val.to_sym)

                raise ArgumentError,
                      "unknown fossil type: #{val.inspect}; " \
                      "must be one of #{Constants::FOSSIL_TYPES.inspect}"
              end

              def validate_cause!(val)
                return if Constants::EXTINCTION_CAUSES.include?(val.to_sym)

                raise ArgumentError,
                      "unknown extinction cause: #{val.inspect}; " \
                      "must be one of #{Constants::EXTINCTION_CAUSES.inspect}"
              end

              def assign_era(depth)
                Constants::ERA_NAMES[depth.to_i.clamp(0, Constants::ERA_NAMES.size - 1)]
              end
            end
          end
        end
      end
    end
  end
end
