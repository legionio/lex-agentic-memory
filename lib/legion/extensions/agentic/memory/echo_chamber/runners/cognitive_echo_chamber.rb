# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module EchoChamber
          module Runners
            module CognitiveEchoChamber
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def create_echo(content:, echo_type: :belief, domain: :general,
                              source_agent: nil, amplitude: 0.5, engine: nil, **)
                raise ArgumentError, 'content cannot be empty' if content.to_s.strip.empty?

                eng  = engine || default_engine
                echo = eng.create_echo(
                  content:      content,
                  echo_type:    echo_type,
                  domain:       domain,
                  source_agent: source_agent,
                  amplitude:    amplitude
                )
                Legion::Logging.debug "[cognitive_echo_chamber] echo created id=#{echo.id} type=#{echo_type} domain=#{domain}"
                { success: true, echo: echo.to_h }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def create_chamber(label:, domain: :general, wall_thickness: 0.5, engine: nil, **)
                raise ArgumentError, 'label cannot be empty' if label.to_s.strip.empty?

                eng     = engine || default_engine
                chamber = eng.create_chamber(label: label, domain: domain, wall_thickness: wall_thickness)
                Legion::Logging.debug "[cognitive_echo_chamber] chamber created id=#{chamber.id} label=#{label}"
                { success: true, chamber: chamber.to_h }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def amplify(echo_id:, rate: 0.1, engine: nil, **)
                eng  = engine || default_engine
                echo = eng.amplify_echo(echo_id: echo_id, rate: rate)
                return { success: false, error: 'echo not found' } unless echo

                Legion::Logging.debug "[cognitive_echo_chamber] amplified echo=#{echo_id} amplitude=#{echo.amplitude}"
                { success: true, echo: echo.to_h }
              end

              def disrupt(chamber_id:, force:, engine: nil, **)
                eng    = engine || default_engine
                result = eng.disrupt_chamber(chamber_id: chamber_id, force: force)
                Legion::Logging.debug "[cognitive_echo_chamber] disrupt chamber=#{chamber_id} success=#{result[:success]}"
                result
              end

              def list_echoes(echo_type: nil, domain: nil, engine: nil, **)
                eng    = engine || default_engine
                echoes = if echo_type
                           eng.echoes_by_type(echo_type: echo_type)
                         else
                           eng.active_echoes
                         end
                echoes = echoes.select { |e| e.domain == domain.to_sym } if domain
                { success: true, echoes: echoes.map(&:to_h), count: echoes.size }
              end

              def chamber_status(engine: nil, **)
                eng = engine || default_engine
                { success: true, **eng.echo_report }
              end

              private

              def default_engine
                @default_engine ||= Helpers::ChamberEngine.new
              end
            end
          end
        end
      end
    end
  end
end
