# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module SemanticSatiation
          module Runners
            module SemanticSatiation
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def expose(label:, domain: :general, **)
                result = satiation_engine.expose_by_label(label: label, domain: domain)
                log.debug("[semantic_satiation] expose: label=#{label} domain=#{domain} " \
                          "fluency=#{result[:fluency]&.round(2)} satiated=#{result[:satiated]}")
                result
              end

              def register(label:, domain: :general, **)
                concept = satiation_engine.register_concept(label: label, domain: domain)
                log.debug("[semantic_satiation] register: label=#{label} domain=#{domain} id=#{concept.id[0..7]}")
                concept.to_h
              end

              def expose_by_id(concept_id:, **)
                result = satiation_engine.expose_concept(concept_id: concept_id)
                if result[:error]
                  log.debug("[semantic_satiation] expose_by_id: not found id=#{concept_id[0..7]}")
                else
                  log.debug("[semantic_satiation] expose_by_id: id=#{concept_id[0..7]} " \
                            "fluency=#{result[:fluency]&.round(2)}")
                end
                result
              end

              def recover(amount: Helpers::Constants::RECOVERY_RATE, **)
                result = satiation_engine.recover_all
                log.debug("[semantic_satiation] recover: amount=#{amount} recovered=#{result[:recovered]}")
                result
              end

              def satiation_status(**)
                summary = satiation_engine.to_h
                log.debug("[semantic_satiation] status: concepts=#{summary[:concept_count]} " \
                          "satiated=#{summary[:satiated_count]}")
                summary
              end

              def domain_satiation(domain:, **)
                avg_fluency = satiation_engine.domain_satiation(domain: domain)
                log.debug("[semantic_satiation] domain_satiation: domain=#{domain} avg_fluency=#{avg_fluency.round(2)}")
                { domain: domain, avg_fluency: avg_fluency }
              end

              def most_exposed(limit: 5, **)
                concepts = satiation_engine.most_exposed(limit: limit)
                log.debug("[semantic_satiation] most_exposed: limit=#{limit} found=#{concepts.size}")
                { concepts: concepts.map(&:to_h), count: concepts.size }
              end

              def freshest_concepts(limit: 5, **)
                concepts = satiation_engine.freshest(limit: limit)
                log.debug("[semantic_satiation] freshest: limit=#{limit} found=#{concepts.size}")
                { concepts: concepts.map(&:to_h), count: concepts.size }
              end

              def novelty_report(**)
                report = satiation_engine.novelty_report
                total = satiation_engine.concepts.size
                log.debug("[semantic_satiation] novelty_report: total=#{total}")
                { distribution: report, total: total }
              end

              def prune_saturated(**)
                removed = satiation_engine.prune_saturated
                log.debug("[semantic_satiation] prune_saturated: removed=#{removed}")
                { removed: removed }
              end

              private

              def satiation_engine
                @satiation_engine ||= Helpers::SatiationEngine.new
              end
            end
          end
        end
      end
    end
  end
end
