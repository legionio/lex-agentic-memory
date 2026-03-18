# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Semantic
          module Helpers
            class KnowledgeStore
              include Constants

              attr_reader :concepts, :retrieval_history

              def initialize
                @concepts          = {}
                @retrieval_history = []
              end

              def store(name:, domain: :general, confidence: nil, properties: {})
                if @concepts.key?(name)
                  existing = @concepts[name]
                  existing.access
                  properties.each { |k, v| existing.set_property(k, v) }
                  return existing
                end

                ensure_capacity
                concept = Concept.new(name: name, domain: domain, confidence: confidence, properties: properties)
                @concepts[name] = concept
                concept
              end

              def relate(source:, target:, type:, confidence: nil)
                store(name: source) unless @concepts.key?(source)
                store(name: target) unless @concepts.key?(target)
                @concepts[source].add_relation(type: type, target_name: target, confidence: confidence)
              end

              def retrieve(name:)
                concept = @concepts[name]
                return nil unless concept

                concept.access
                record_retrieval(name)
                concept
              end

              def query_relations(name:, type: nil)
                concept = @concepts[name]
                return [] unless concept

                concept.access
                if type
                  concept.relations_of_type(type)
                else
                  concept.relations
                end
              end

              def check_is_a(concept_name, category_name)
                rels = query_relations(name: concept_name, type: :is_a)
                rels.any? { |r| r[:target] == category_name }
              end

              def instances_of(category_name)
                @concepts.values.select do |c|
                  c.relations.any? { |r| r[:type] == :is_a && r[:target] == category_name }
                end
              end

              def spreading_activation(seed:, hops: MAX_SPREAD_HOPS)
                activated = {}
                queue = [[seed, 1.0]]

                hops.times do
                  next_queue = []
                  queue.each do |name, strength|
                    next if strength < SPREAD_THRESHOLD
                    next if activated.key?(name) && activated[name] >= strength

                    activated[name] = strength
                    concept = @concepts[name]
                    next unless concept

                    concept.related_concepts.each do |related|
                      next_strength = strength * SPREAD_FACTOR
                      next_queue << [related, next_strength] if next_strength >= SPREAD_THRESHOLD
                    end
                  end
                  queue = next_queue
                end

                activated.sort_by { |_, s| -s }.to_h
              end

              def concepts_in_domain(domain)
                @concepts.values.select { |c| c.domain == domain }
              end

              def search(query)
                @concepts.values.select { |c| c.name.to_s.include?(query.to_s) }
              end

              def decay_all
                @concepts.each_value(&:decay)
                @concepts.reject! { |_, c| c.faded? }
              end

              def concept_count
                @concepts.size
              end

              def relation_count
                @concepts.values.sum { |c| c.relations.size }
              end

              def to_h
                {
                  concepts:     concept_count,
                  relations:    relation_count,
                  domains:      @concepts.values.map(&:domain).uniq.size,
                  history_size: @retrieval_history.size
                }
              end

              private

              def ensure_capacity
                return if @concepts.size < MAX_CONCEPTS

                weakest = @concepts.min_by { |_, c| c.confidence }
                @concepts.delete(weakest.first) if weakest
              end

              def record_retrieval(name)
                @retrieval_history << { name: name, at: Time.now.utc }
                @retrieval_history.shift while @retrieval_history.size > MAX_HISTORY
              end
            end
          end
        end
      end
    end
  end
end
