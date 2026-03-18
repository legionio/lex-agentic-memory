# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Echo
          module Runners
            module CognitiveEcho
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def create_echo(content:, echo_type: :thought, domain: :general, intensity: 0.8, engine: nil, **)
                eng = engine || default_engine
                echo = eng.create_echo(content: content, echo_type: echo_type, domain: domain, intensity: intensity)
                { success: true, echo: echo.to_h }
              end

              def reinforce_echo(echo_id:, amount: 0.15, engine: nil, **)
                eng = engine || default_engine
                echo = eng.reinforce_echo(echo_id: echo_id, amount: amount)
                return { success: false, error: 'echo not found' } unless echo

                { success: true, echo: echo.to_h }
              end

              def decay_all(engine: nil, **)
                eng = engine || default_engine
                result = eng.decay_all!
                { success: true, **result }
              end

              def active_echoes(engine: nil, **)
                eng = engine || default_engine
                { success: true, echoes: eng.active_echoes.map(&:to_h), count: eng.active_echoes.size }
              end

              def priming_echoes(engine: nil, **)
                eng = engine || default_engine
                { success: true, echoes: eng.priming_echoes.map(&:to_h), count: eng.priming_echoes.size }
              end

              def interfering_echoes(engine: nil, **)
                eng = engine || default_engine
                { success: true, echoes: eng.interfering_echoes.map(&:to_h), count: eng.interfering_echoes.size }
              end

              def echoes_by_domain(domain:, engine: nil, **)
                eng = engine || default_engine
                echoes = eng.echoes_by_domain(domain: domain)
                { success: true, echoes: echoes.map(&:to_h), count: echoes.size }
              end

              def strongest_echoes(limit: 5, engine: nil, **)
                eng = engine || default_engine
                { success: true, echoes: eng.strongest_echoes(limit: limit).map(&:to_h) }
              end

              def priming_effect(domain:, engine: nil, **)
                eng = engine || default_engine
                effect = eng.priming_effect_for(domain: domain)
                label = Helpers::Constants.label_for(Helpers::Constants::EFFECT_LABELS, effect)
                { success: true, domain: domain.to_sym, priming_effect: effect, effect_label: label }
              end

              def echo_status(engine: nil, **)
                eng = engine || default_engine
                { success: true, **eng.echo_report }
              end

              private

              def default_engine
                @default_engine ||= Helpers::EchoEngine.new
              end
            end
          end
        end
      end
    end
  end
end
