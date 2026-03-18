# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Palimpsest
          module Runners
            module CognitivePalimpsest
              include Helpers::Constants
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def create_palimpsest(topic:, domain: :unknown, engine: nil, **)
                p = resolve_engine(engine).create(topic: topic, domain: domain)
                return { success: false, reason: :limit_or_duplicate } unless p

                { success: true, id: p.id, topic: p.topic, domain: p.domain }
              end

              def overwrite_belief(topic:, content:, confidence: DEFAULT_CONFIDENCE,
                                   author: :system, engine: nil, **)
                layer = resolve_engine(engine).overwrite(
                  topic:      topic,
                  content:    content,
                  confidence: confidence,
                  author:     author
                )
                return { success: false, reason: :limit_reached } unless layer

                { success: true, layer_id: layer.id, version: layer.version,
                  confidence: layer.confidence.round(4) }
              end

              def peek_through_belief(topic:, depth: 1, engine: nil, **)
                layers = resolve_engine(engine).peek_through(topic: topic, depth: depth)
                { success: true, layers: layers, count: layers.size }
              end

              def erode_belief(topic:, rate: EROSION_RATE, engine: nil, **)
                result = resolve_engine(engine).erode(topic: topic, rate: rate)
                return { success: false, reason: :not_found } if result.nil?

                { success: true, topic: topic, confidence: result.round(4) }
              end

              def ghost_layers(topic:, engine: nil, **)
                layers = resolve_engine(engine).ghost_layers_for(topic: topic)
                { success: true, layers: layers, count: layers.size }
              end

              def all_ghost_layers(engine: nil, **)
                layers = resolve_engine(engine).all_ghost_layers
                { success: true, layers: layers, count: layers.size }
              end

              def domain_archaeology(domain:, engine: nil, **)
                layers = resolve_engine(engine).domain_archaeology(domain: domain)
                { success: true, layers: layers, count: layers.size }
              end

              def belief_drift(topic:, engine: nil, **)
                result = resolve_engine(engine).belief_drift(topic: topic)
                return { success: false, reason: :not_found } unless result

                { success: true }.merge(result)
              end

              def overwrite_frequency(topic:, engine: nil, **)
                count = resolve_engine(engine).overwrite_frequency(topic: topic)
                return { success: false, reason: :not_found } if count.nil?

                { success: true, topic: topic, overwrite_count: count }
              end

              def most_rewritten(limit: 10, engine: nil, **)
                palimpsests = resolve_engine(engine).most_rewritten(limit: limit)
                { success: true, palimpsests: palimpsests, count: palimpsests.size }
              end

              def decay_all_ghosts(ghost_rate: GHOST_DECAY, engine: nil, **)
                resolve_engine(engine).decay_all!(ghost_rate: ghost_rate)
                { success: true }
              end

              def palimpsest_report(engine: nil, **)
                report = resolve_engine(engine).palimpsest_report
                { success: true }.merge(report)
              end

              private

              def resolve_engine(engine)
                engine || default_engine
              end

              def default_engine
                @default_engine ||= Helpers::PalimpsestEngine.new
              end
            end
          end
        end
      end
    end
  end
end
