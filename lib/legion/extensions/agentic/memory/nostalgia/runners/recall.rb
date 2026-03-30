# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Nostalgia
          module Runners
            module Recall
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def store_memory(content:, domain: :unknown, warmth: Helpers::Constants::DEFAULT_WARMTH,
                               original_valence: 0.5, engine: nil, **)
                eng = engine || nostalgia_engine
                memory = eng.create_memory(
                  content:          content,
                  domain:           domain,
                  warmth:           warmth,
                  original_valence: original_valence
                )
                log.debug("[cognitive_nostalgia] stored memory id=#{memory.id} domain=#{memory.domain} warmth=#{memory.warmth.round(2)}")
                { success: true, memory: memory.to_h }
              end

              def trigger_nostalgia(trigger:, domain: nil, intensity_hint: nil, engine: nil, **)
                eng = engine || nostalgia_engine
                events = eng.trigger_nostalgia(trigger: trigger, domain: domain, intensity_hint: intensity_hint)
                log.debug("[cognitive_nostalgia] triggered nostalgia: trigger=#{trigger} events=#{events.size}")
                { success: true, events: events.map(&:to_h), count: events.size }
              end

              def age_memories(engine: nil, **)
                eng = engine || nostalgia_engine
                eng.age_all!
                log.debug("[cognitive_nostalgia] aged #{eng.memories.size} memories")
                { success: true, memory_count: eng.memories.size }
              end

              def nostalgia_report(engine: nil, **)
                eng = engine || nostalgia_engine
                report = eng.nostalgia_report
                idx = report[:rosy_retrospection_index].round(2)
                pro = report[:nostalgia_proneness].round(2)
                log.debug("[cognitive_nostalgia] report: index=#{idx} proneness=#{pro}")
                { success: true, **report }
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
