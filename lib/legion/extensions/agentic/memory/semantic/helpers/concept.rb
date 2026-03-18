# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Semantic
          module Helpers
            class Concept
              attr_reader :id, :name, :domain, :properties, :relations, :created_at
              attr_accessor :confidence, :access_count

              def initialize(name:, domain: :general, confidence: nil, properties: {})
                @id           = SecureRandom.uuid
                @name         = name
                @domain       = domain
                @confidence   = (confidence || Constants::DEFAULT_CONFIDENCE).clamp(0.0, 1.0)
                @properties   = properties.dup
                @relations    = []
                @access_count = 0
                @created_at   = Time.now.utc
              end

              def add_relation(type:, target_name:, confidence: nil)
                return false unless Constants::RELATION_TYPES.include?(type)

                existing = @relations.find { |r| r[:type] == type && r[:target] == target_name }
                if existing
                  existing[:confidence] = [existing[:confidence] + Constants::ACCESS_BOOST, 1.0].min
                  return existing
                end

                trim_relations if @relations.size >= Constants::MAX_RELATIONS_PER_CONCEPT
                rel = { type: type, target: target_name, confidence: (confidence || Constants::DEFAULT_CONFIDENCE).clamp(0.0, 1.0) }
                @relations << rel
                rel
              end

              def relations_of_type(type)
                @relations.select { |r| r[:type] == type }
              end

              def related_concepts
                @relations.map { |r| r[:target] }.uniq
              end

              def set_property(key, value)
                @properties[key] = value
              end

              def get_property(key)
                @properties[key]
              end

              def access
                @access_count += 1
                @confidence = [@confidence + Constants::ACCESS_BOOST, 1.0].min
              end

              def decay
                @confidence = [@confidence - Constants::CONFIDENCE_DECAY, Constants::CONFIDENCE_FLOOR].max
                @relations.each { |r| r[:confidence] = [r[:confidence] - Constants::CONFIDENCE_DECAY, Constants::CONFIDENCE_FLOOR].max }
                @relations.reject! { |r| r[:confidence] <= Constants::CONFIDENCE_FLOOR }
              end

              def faded?
                @confidence <= Constants::CONFIDENCE_FLOOR
              end

              def label
                Constants::CONFIDENCE_LABELS.each { |range, lbl| return lbl if range.cover?(@confidence) }
                :uncertain
              end

              def to_h
                {
                  id:           @id,
                  name:         @name,
                  domain:       @domain,
                  confidence:   @confidence,
                  properties:   @properties,
                  relations:    @relations,
                  access_count: @access_count,
                  label:        label,
                  created_at:   @created_at
                }
              end

              private

              def trim_relations
                @relations.sort_by! { |r| r[:confidence] }
                @relations.shift
              end
            end
          end
        end
      end
    end
  end
end
