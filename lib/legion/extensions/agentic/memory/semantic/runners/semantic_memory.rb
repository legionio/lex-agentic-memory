# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Semantic
          module Runners
            module SemanticMemory
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def store_concept(name:, domain: :general, confidence: nil, properties: {}, **)
                concept = knowledge_store.store(name: name, domain: domain, confidence: confidence, properties: properties)
                log.debug("[semantic_memory] store: name=#{name} domain=#{domain} conf=#{concept.confidence.round(3)}")
                { success: true, concept: concept.to_h }
              end

              def relate_concepts(source:, target:, type:, confidence: nil, **)
                type_sym = type.to_sym
                result = knowledge_store.relate(source: source, target: target, type: type_sym, confidence: confidence)
                log.debug("[semantic_memory] relate: #{source} --#{type_sym}--> #{target}")
                { success: true, source: source, target: target, type: type_sym, relation: result }
              end

              def retrieve_concept(name:, **)
                concept = knowledge_store.retrieve(name: name)
                if concept
                  log.debug("[semantic_memory] retrieve: name=#{name} conf=#{concept.confidence.round(3)}")
                  { success: true, found: true, concept: concept.to_h }
                else
                  log.debug("[semantic_memory] retrieve: name=#{name} not_found")
                  { success: true, found: false, name: name }
                end
              end

              def query_concept_relations(name:, type: nil, **)
                relations = knowledge_store.query_relations(name: name, type: type&.to_sym)
                log.debug("[semantic_memory] query_relations: name=#{name} type=#{type} count=#{relations.size}")
                { success: true, name: name, relations: relations, count: relations.size }
              end

              def check_category(concept:, category:, **)
                result = knowledge_store.check_is_a(concept, category)
                log.debug("[semantic_memory] check_category: #{concept} is_a #{category} = #{result}")
                { success: true, concept: concept, category: category, is_member: result }
              end

              def find_instances(category:, **)
                instances = knowledge_store.instances_of(category)
                log.debug("[semantic_memory] instances_of: #{category} count=#{instances.size}")
                { success: true, category: category, instances: instances.map(&:name), count: instances.size }
              end

              def activate_spread(seed:, hops: nil, **)
                hop_count = hops || Helpers::Constants::MAX_SPREAD_HOPS
                activated = knowledge_store.spreading_activation(seed: seed, hops: hop_count)
                log.debug("[semantic_memory] spread: seed=#{seed} hops=#{hop_count} activated=#{activated.size}")
                { success: true, seed: seed, activated: activated, count: activated.size }
              end

              def concepts_in(domain:, **)
                concepts = knowledge_store.concepts_in_domain(domain)
                log.debug("[semantic_memory] domain_query: domain=#{domain} count=#{concepts.size}")
                { success: true, domain: domain, concepts: concepts.map(&:name), count: concepts.size }
              end

              def update_semantic_memory(**)
                knowledge_store.decay_all
                log.debug("[semantic_memory] tick: concepts=#{knowledge_store.concept_count} " \
                          "relations=#{knowledge_store.relation_count}")
                {
                  success:   true,
                  concepts:  knowledge_store.concept_count,
                  relations: knowledge_store.relation_count
                }
              end

              def semantic_memory_stats(**)
                { success: true, stats: knowledge_store.to_h }
              end

              private

              def knowledge_store
                @knowledge_store ||= Helpers::KnowledgeStore.new
              end
            end
          end
        end
      end
    end
  end
end
