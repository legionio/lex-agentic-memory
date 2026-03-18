# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Echo
          module Helpers
            class EchoEngine
              include Constants

              def initialize
                @echoes = {}
              end

              def create_echo(content:, echo_type: :thought, domain: :general, intensity: DEFAULT_INTENSITY)
                prune_silent
                echo = Echo.new(content: content, echo_type: echo_type, domain: domain, intensity: intensity)
                @echoes[echo.id] = echo
                echo
              end

              def reinforce_echo(echo_id:, amount: REINFORCEMENT)
                echo = @echoes[echo_id]
                return nil unless echo

                echo.reinforce!(amount)
                echo
              end

              def decay_all!
                @echoes.each_value(&:decay!)
                prune_silent
                { echoes_decayed: @echoes.size, pruned: count_silent }
              end

              def active_echoes = @echoes.values.select(&:active?)
              def priming_echoes = @echoes.values.select(&:priming?)
              def interfering_echoes = @echoes.values.select(&:interfering?)

              def echoes_by_type(echo_type:)
                @echoes.values.select { |e| e.echo_type == echo_type.to_sym }
              end

              def echoes_by_domain(domain:)
                @echoes.values.select { |e| e.domain == domain.to_sym }
              end

              def strongest_echoes(limit: 5) = @echoes.values.sort_by { |e| -e.intensity }.first(limit)
              def faintest_echoes(limit: 5) = @echoes.values.select(&:active?).sort_by(&:intensity).first(limit)

              def echo_chamber_score
                return 0.0 if @echoes.empty?

                domains = @echoes.values.map(&:domain).uniq
                return 1.0 if domains.size <= 1

                domain_concentration(domains)
              end

              def chamber_label = Constants.label_for(CHAMBER_LABELS, echo_chamber_score)

              def priming_effect_for(domain:)
                matching = echoes_by_domain(domain: domain).select(&:priming?)
                return 0.0 if matching.empty?

                matching.sum(&:intensity).clamp(0.0, 1.0).round(10)
              end

              def interference_level
                interfering = interfering_echoes
                return 0.0 if interfering.empty?

                (interfering.sum(&:intensity) / @echoes.size).clamp(0.0, 1.0).round(10)
              end

              def average_intensity
                return 0.0 if @echoes.empty?

                (@echoes.values.sum(&:intensity) / @echoes.size).round(10)
              end

              def echo_report
                {
                  total_echoes:       @echoes.size,
                  active_count:       active_echoes.size,
                  priming_count:      priming_echoes.size,
                  interfering_count:  interfering_echoes.size,
                  average_intensity:  average_intensity,
                  echo_chamber_score: echo_chamber_score,
                  chamber_label:      chamber_label,
                  interference_level: interference_level,
                  strongest:          strongest_echoes(limit: 3).map(&:to_h)
                }
              end

              def to_h
                {
                  total_echoes:      @echoes.size,
                  active:            active_echoes.size,
                  average_intensity: average_intensity,
                  chamber_score:     echo_chamber_score
                }
              end

              private

              def domain_concentration(domains)
                intensities = domains.map { |d| @echoes.values.select { |e| e.domain == d }.sum(&:intensity) }
                total = intensities.sum
                return 0.0 if total.zero?

                (intensities.max / total).round(10)
              end

              def count_silent
                @echoes.values.count(&:silent?)
              end

              def prune_silent
                return if @echoes.size < MAX_ECHOES

                silent = @echoes.values.select(&:silent?)
                silent.each { |e| @echoes.delete(e.id) }
                return unless @echoes.size >= MAX_ECHOES

                faintest = @echoes.values.min_by(&:intensity)
                @echoes.delete(faintest.id) if faintest
              end
            end
          end
        end
      end
    end
  end
end
