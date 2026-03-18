# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Nostalgia
          module Runners
            module Analysis
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def warmth_by_domain(engine: nil, **)
                eng = engine || nostalgia_engine
                by_domain = eng.warmth_by_domain
                Legion::Logging.debug "[cognitive_nostalgia] warmth_by_domain: #{by_domain.size} domains"
                { success: true, warmth_by_domain: by_domain }
              end

              def rosy_retrospection_index(engine: nil, **)
                eng = engine || nostalgia_engine
                index = eng.rosy_retrospection_index
                label = Helpers::Constants.label_for(Helpers::Constants::RETROSPECTION_LABELS, index)
                Legion::Logging.debug "[cognitive_nostalgia] rosy_retrospection_index=#{index.round(2)} label=#{label}"
                { success: true, index: index, label: label }
              end

              def nostalgia_proneness(engine: nil, **)
                eng = engine || nostalgia_engine
                proneness = eng.nostalgia_proneness
                label = Helpers::Constants.label_for(Helpers::Constants::NOSTALGIA_LABELS, proneness)
                Legion::Logging.debug "[cognitive_nostalgia] nostalgia_proneness=#{proneness.round(2)} label=#{label}"
                { success: true, proneness: proneness, label: label }
              end

              def most_nostalgic_domains(engine: nil, **)
                eng = engine || nostalgia_engine
                domains = eng.most_nostalgic_domains
                Legion::Logging.debug "[cognitive_nostalgia] most_nostalgic_domains: top=#{domains.first&.fetch(:domain, :none)}"
                { success: true, domains: domains }
              end

              def bittersweet_memories(engine: nil, **)
                eng = engine || nostalgia_engine
                memories = eng.bittersweet_memories
                Legion::Logging.debug "[cognitive_nostalgia] bittersweet_memories: count=#{memories.size}"
                { success: true, memories: memories, count: memories.size }
              end

              private

              def nostalgia_engine
                @nostalgia_engine ||= Helpers::NostalgiaEngine.new
              end
            end
          end
        end
      end
    end
  end
end
