# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module SemanticSatiation
          module Helpers
            class SatiationEngine
              include Constants

              attr_reader :concepts

              def initialize
                @concepts = {}
              end

              def register_concept(label:, domain: :general)
                prune_saturated if @concepts.size >= MAX_CONCEPTS

                existing = find_by_label(label)
                return existing if existing

                concept = Concept.new(label: label, domain: domain)
                @concepts[concept.id] = concept
                concept
              end

              def expose_concept(concept_id:)
                concept = @concepts[concept_id]
                return { error: :not_found, concept_id: concept_id } unless concept

                concept.expose!
                concept.to_h
              end

              def expose_by_label(label:, domain: :general)
                concept = find_by_label(label) || register_concept(label: label, domain: domain)
                concept.expose!
                concept.to_h
              end

              def recover_all
                @concepts.each_value(&:recover!)
                { recovered: @concepts.size }
              end

              def satiated_concepts
                @concepts.values.select(&:satiated?)
              end

              def most_exposed(limit: 5)
                @concepts.values.sort_by { |c| -c.exposure_count }.first(limit)
              end

              def freshest(limit: 5)
                @concepts.values.sort_by { |c| -c.fluency }.first(limit)
              end

              def domain_satiation(domain:)
                domain_concepts = @concepts.values.select { |c| c.domain == domain }
                return 0.0 if domain_concepts.empty?

                avg = domain_concepts.sum(&:fluency) / domain_concepts.size.to_f
                avg.round(10)
              end

              def novelty_report
                distribution = Hash.new(0)
                @concepts.each_value do |c|
                  distribution[c.novelty_label] += 1
                end
                distribution
              end

              def prune_saturated
                to_remove = @concepts.select { |_, c| c.fluency <= 0.05 }.keys
                to_remove.each { |id| @concepts.delete(id) }
                to_remove.size
              end

              def to_h
                {
                  concept_count:  @concepts.size,
                  satiated_count: satiated_concepts.size,
                  novelty_report: novelty_report,
                  most_exposed:   most_exposed.map(&:to_h),
                  freshest:       freshest.map(&:to_h)
                }
              end

              private

              def find_by_label(label)
                @concepts.values.find { |c| c.label == label }
              end
            end
          end
        end
      end
    end
  end
end
