# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Archaeology
          module Runners
            module CognitiveArchaeology
              extend self

              def create_site(domain:, engine: nil, **)
                eng  = resolve_engine(engine)
                site = eng.create_site(domain: domain)
                { success: true, site: site.survey }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def dig(site_id:, engine: nil, **)
                eng    = resolve_engine(engine)
                result = eng.dig(site_id: site_id)
                { success: true }.merge(result)
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def excavate(site_id:, engine: nil, **)
                eng      = resolve_engine(engine)
                artifact = eng.excavate(site_id: site_id)
                { success: true, artifact: artifact.to_h }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def restore_artifact(artifact_id:, boost: 0.15, engine: nil, **)
                eng      = resolve_engine(engine)
                artifact = eng.restore_artifact(
                  artifact_id: artifact_id, boost: boost
                )
                { success: true, artifact: artifact.to_h }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def list_artifacts(engine: nil, type: nil, domain: nil,
                                 depth_level: nil, **)
                eng     = resolve_engine(engine)
                results = filter_results(eng.all_artifacts,
                                         type: type, domain: domain,
                                         depth_level: depth_level)
                { success: true, artifacts: results.map(&:to_h),
                  count: results.size }
              end

              def decay_all(rate: Helpers::Constants::PRESERVATION_DECAY, engine: nil, **)
                eng = resolve_engine(engine)
                eng.decay_all!(rate: rate)
                { success: true, remaining: eng.all_artifacts.size }
              end

              def archaeology_status(engine: nil, **)
                eng = resolve_engine(engine)
                { success: true, report: eng.archaeology_report }
              end

              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              private

              def filter_results(artifacts, type:, domain:, depth_level:)
                r = artifacts
                r = r.select { |a| a.artifact_type == type.to_sym } if type
                r = r.select { |a| a.domain == domain.to_sym } if domain
                r = r.select { |a| a.depth_level == depth_level.to_sym } if depth_level
                r
              end

              def resolve_engine(engine)
                engine || default_engine
              end

              def default_engine
                @default_engine ||= Helpers::ArchaeologyEngine.new
              end
            end
          end
        end
      end
    end
  end
end
