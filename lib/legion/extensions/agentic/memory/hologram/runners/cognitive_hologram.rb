# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Hologram
          module Runners
            module CognitiveHologram
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def create(domain: :general, content: '', engine: nil, **)
                raise ArgumentError, 'content cannot be empty' if content.to_s.strip.empty?

                target_engine = engine || default_engine
                hologram = target_engine.create_hologram(domain: domain, content: content)

                Legion::Logging.debug "[cognitive_hologram] created hologram: domain=#{domain} id=#{hologram.id}"

                { success: true, hologram: hologram.to_h }
              rescue StandardError => e
                Legion::Logging.error "[cognitive_hologram] create failed: #{e.message}"
                { success: false, error: e.message }
              end

              def fragment(hologram_id:, count: 4, engine: nil, **)
                target_engine = engine || default_engine
                fragments = target_engine.fragment_hologram(hologram_id: hologram_id, count: count)

                unless fragments
                  Legion::Logging.warn "[cognitive_hologram] fragment: hologram not found id=#{hologram_id}"
                  return { success: false, reason: :hologram_not_found }
                end

                Legion::Logging.debug "[cognitive_hologram] fragmented hologram id=#{hologram_id} count=#{fragments.size}"
                { success: true, fragment_count: fragments.size, fragments: fragments.map(&:to_h) }
              rescue StandardError => e
                Legion::Logging.error "[cognitive_hologram] fragment failed: #{e.message}"
                { success: false, error: e.message }
              end

              def reconstruct(hologram_id:, fragment_ids: [], engine: nil, **)
                target_engine = engine || default_engine
                result = target_engine.reconstruct_from_fragments(
                  hologram_id:  hologram_id,
                  fragment_ids: fragment_ids
                )

                Legion::Logging.debug "[cognitive_hologram] reconstruct hologram=#{hologram_id} " \
                                      "fragments=#{fragment_ids.size} success=#{result[:success]}"

                result.merge(success: result[:success])
              rescue StandardError => e
                Legion::Logging.error "[cognitive_hologram] reconstruct failed: #{e.message}"
                { success: false, error: e.message }
              end

              def list_holograms(limit: 20, engine: nil, **)
                target_engine = engine || default_engine
                holograms = target_engine.holograms.first(limit)

                Legion::Logging.debug "[cognitive_hologram] list_holograms: count=#{holograms.size} limit=#{limit}"
                { success: true, holograms: holograms.map(&:to_h), count: holograms.size }
              rescue StandardError => e
                Legion::Logging.error "[cognitive_hologram] list_holograms failed: #{e.message}"
                { success: false, error: e.message }
              end

              def interference_check(hologram_id_a:, hologram_id_b:, engine: nil, **)
                target_engine = engine || default_engine
                result = target_engine.measure_interference(
                  hologram_id_a: hologram_id_a,
                  hologram_id_b: hologram_id_b
                )

                Legion::Logging.debug '[cognitive_hologram] interference_check: ' \
                                      "a=#{hologram_id_a} b=#{hologram_id_b} score=#{result[:interference]}"

                result.merge(success: true)
              rescue StandardError => e
                Legion::Logging.error "[cognitive_hologram] interference_check failed: #{e.message}"
                { success: false, error: e.message }
              end

              def hologram_status(engine: nil, **)
                target_engine = engine || default_engine
                report = target_engine.hologram_report

                Legion::Logging.debug "[cognitive_hologram] status: total=#{report[:total_holograms]} " \
                                      "avg_resolution=#{report[:average_resolution].round(2)}"

                { success: true, report: report }
              rescue StandardError => e
                Legion::Logging.error "[cognitive_hologram] hologram_status failed: #{e.message}"
                { success: false, error: e.message }
              end

              private

              def default_engine
                @default_engine ||= Helpers::HologramEngine.new
              end
            end
          end
        end
      end
    end
  end
end
