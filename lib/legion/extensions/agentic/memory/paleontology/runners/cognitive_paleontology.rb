# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Paleontology
          module Runners
            module CognitivePaleontology
              extend self

              def record_extinction(fossil_type:, domain:, content:,
                                    extinction_cause:, stratum_depth: 0,
                                    significance: nil, engine: nil, **)
                eng    = resolve_engine(engine)
                fossil = eng.record_extinction(
                  fossil_type: fossil_type, domain: domain, content: content,
                  extinction_cause: extinction_cause,
                  stratum_depth: stratum_depth, significance: significance
                )
                { success: true, fossil: fossil.to_h }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def begin_excavation(target_stratum:, engine: nil, **)
                eng = resolve_engine(engine)
                exc = eng.begin_excavation(target_stratum: target_stratum)
                { success: true, excavation: exc.to_h }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def excavate(excavation_id:, engine: nil, **)
                eng    = resolve_engine(engine)
                fossil = eng.excavate!(excavation_id: excavation_id)
                if fossil
                  { success: true, fossil: fossil.to_h }
                else
                  { success: true, fossil: nil, message: 'no fossils at this stratum' }
                end
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def complete_excavation(excavation_id:, engine: nil, **)
                eng = resolve_engine(engine)
                exc = eng.complete_excavation(excavation_id: excavation_id)
                { success: true, excavation: exc.to_h }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def list_fossils(engine: nil, fossil_type: nil,
                               extinction_cause: nil, **)
                eng     = resolve_engine(engine)
                results = filter_fossils(eng.all_fossils,
                                         fossil_type:      fossil_type,
                                         extinction_cause: extinction_cause)
                { success: true, fossils: results.map(&:to_h),
                  count: results.size }
              end

              def paleontology_status(engine: nil, **)
                eng = resolve_engine(engine)
                { success: true, report: eng.paleontology_report }
              end

              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              private

              def filter_fossils(fossils, fossil_type:, extinction_cause:)
                r = fossils
                r = r.select { |f| f.fossil_type == fossil_type.to_sym } if fossil_type
                r = r.select { |f| f.extinction_cause == extinction_cause.to_sym } if extinction_cause
                r
              end

              def resolve_engine(engine)
                engine || default_engine
              end

              def default_engine
                @default_engine ||= Helpers::PaleontologyEngine.new
              end
            end
          end
        end
      end
    end
  end
end
