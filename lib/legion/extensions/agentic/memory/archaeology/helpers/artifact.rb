# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Archaeology
          module Helpers
            class Artifact
              attr_reader :id, :artifact_type, :domain, :content, :depth_level,
                          :discovered_at, :origin_epoch, :contextual_links

              attr_accessor :preservation_quality, :integrity

              alias type artifact_type

              def initialize(type:, domain:, content:, depth_level:,
                             preservation: nil, integrity: nil,
                             origin_epoch: nil, contextual_links: nil)
                validate_type!(type)
                validate_domain!(domain)
                validate_depth!(depth_level)

                @id               = SecureRandom.uuid
                @artifact_type    = type.to_sym
                @domain           = domain.to_sym
                @content          = content.to_s
                @depth_level      = depth_level.to_sym
                pres = (preservation || Constants::DEFAULT_PRESERVATION).to_f
                @preservation_quality = pres.clamp(0.0, 1.0).round(10)
                @integrity        = (integrity || derive_integrity).clamp(0.0, 1.0).round(10)
                @discovered_at    = Time.now.utc
                @origin_epoch     = origin_epoch || (Time.now.utc - rand(0..31_536_000))
                @contextual_links = Array(contextual_links).dup
              end

              def preservation
                @preservation_quality
              end

              def preservation=(val)
                @preservation_quality = val.to_f.clamp(0.0, 1.0).round(10)
              end

              def decay!(rate: Constants::PRESERVATION_DECAY)
                @preservation_quality = (@preservation_quality - rate.abs).clamp(0.0, 1.0).round(10)
                @integrity            = (@integrity - (rate.abs * 0.5)).clamp(0.0, 1.0).round(10)
                self
              end

              def restore!(boost: 0.15)
                @preservation_quality = (@preservation_quality + boost.abs).clamp(0.0, 1.0).round(10)
                @integrity            = (@integrity + (boost.abs * 0.5)).clamp(0.0, 1.0).round(10)
                self
              end

              def fragment?
                @preservation_quality < 0.3
              end

              def well_preserved?
                @preservation_quality > 0.7
              end

              def ancient?
                (Time.now.utc - @origin_epoch) > 15_552_000
              end

              def preservation_label
                match_label(Constants::PRESERVATION_LABELS, @preservation_quality)
              end

              def integrity_label
                match_label(Constants::INTEGRITY_LABELS, @integrity)
              end

              def link_to(other_id)
                @contextual_links << other_id unless @contextual_links.include?(other_id)
              end

              def to_h
                {
                  id:                   @id,
                  type:                 @artifact_type,
                  artifact_type:        @artifact_type,
                  domain:               @domain,
                  content:              @content,
                  depth_level:          @depth_level,
                  preservation:         @preservation_quality,
                  preservation_quality: @preservation_quality,
                  preservation_label:   preservation_label,
                  integrity:            @integrity,
                  integrity_label:      integrity_label,
                  discovered_at:        @discovered_at,
                  origin_epoch:         @origin_epoch,
                  contextual_links:     @contextual_links,
                  fragment:             fragment?,
                  well_preserved:       well_preserved?,
                  ancient:              ancient?
                }
              end

              private

              def derive_integrity
                depth_mod = Constants::DEPTH_PRESERVATION_MODIFIER.fetch(@depth_level, 0.0)
                (0.8 + depth_mod + rand(-0.1..0.1)).clamp(0.0, 1.0)
              end

              def validate_type!(type_val)
                return if Constants::ARTIFACT_TYPES.include?(type_val.to_sym)

                raise ArgumentError,
                      "unknown artifact type: #{type_val.inspect}; " \
                      "must be one of #{Constants::ARTIFACT_TYPES.inspect}"
              end

              def validate_domain!(domain_val)
                return if Constants::DOMAIN_TYPES.include?(domain_val.to_sym)

                raise ArgumentError,
                      "unknown domain: #{domain_val.inspect}; " \
                      "must be one of #{Constants::DOMAIN_TYPES.inspect}"
              end

              def validate_depth!(depth_val)
                return if Constants::EXCAVATION_DEPTH_LEVELS.include?(depth_val.to_sym)

                raise ArgumentError,
                      "unknown depth level: #{depth_val.inspect}; " \
                      "must be one of #{Constants::EXCAVATION_DEPTH_LEVELS.inspect}"
              end

              def match_label(label_table, value)
                label_table.each { |range, label| return label if range.cover?(value) }
                label_table.last.last
              end
            end
          end
        end
      end
    end
  end
end
