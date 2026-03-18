# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module EchoChamber
          module Helpers
            class ChamberEngine
              include Constants

              def initialize
                @echoes           = {}
                @chambers         = {}
                @disruption_history = []
              end

              def create_echo(content:, echo_type: :belief, domain: :general,
                              source_agent: nil, amplitude: DEFAULT_AMPLITUDE)
                prune_echoes
                echo = Echo.new(
                  content:      content,
                  echo_type:    echo_type,
                  domain:       domain,
                  source_agent: source_agent,
                  amplitude:    amplitude
                )
                @echoes[echo.id] = echo
                echo
              end

              def create_chamber(label:, domain: :general, wall_thickness: DEFAULT_WALL_THICKNESS)
                prune_chambers
                chamber = Chamber.new(label: label, domain: domain, wall_thickness: wall_thickness)
                @chambers[chamber.id] = chamber
                chamber
              end

              def amplify_echo(echo_id:, rate: AMPLIFICATION_RATE)
                echo = @echoes[echo_id]
                return nil unless echo

                echo.amplify!(rate)
                echo
              end

              def disrupt_chamber(chamber_id:, force:)
                chamber = @chambers[chamber_id]
                return { success: false, error: 'chamber not found' } unless chamber

                result = chamber.disrupt!(force)
                record_disruption(chamber_id: chamber_id, force: force, result: result) if result[:success]
                result
              end

              def decay_all!
                echo_count = @echoes.size
                @echoes.each_value { |e| e.dampen!(DECAY_RATE) }
                prune_silent_echoes
                { decayed: echo_count, remaining: @echoes.size, pruned: echo_count - @echoes.size }
              end

              def echoes_by_type(echo_type:)
                @echoes.values.select { |e| e.echo_type == echo_type.to_sym }
              end

              def loudest_echoes(limit: 5)
                @echoes.values.sort_by { |e| -e.amplitude }.first(limit)
              end

              def most_sealed_chambers(limit: 5)
                @chambers.values.sort_by { |c| -c.wall_thickness }.first(limit)
              end

              def disruption_history
                @disruption_history.dup
              end

              def add_echo_to_chamber(echo_id:, chamber_id:)
                echo    = @echoes[echo_id]
                chamber = @chambers[chamber_id]
                return { success: false, error: 'echo not found' } unless echo
                return { success: false, error: 'chamber not found' } unless chamber

                added = chamber.add_echo(echo)
                { success: added, echo_id: echo_id, chamber_id: chamber_id }
              end

              def echo_report
                {
                  total_echoes:      @echoes.size,
                  active_echoes:     active_echoes.size,
                  resonating_echoes: resonating_echoes.size,
                  total_chambers:    @chambers.size,
                  sealed_chambers:   @chambers.values.count(&:sealed?),
                  porous_chambers:   @chambers.values.count(&:porous?),
                  disruption_count:  @disruption_history.size,
                  loudest:           loudest_echoes(limit: 3).map(&:to_h)
                }
              end

              def active_echoes
                @echoes.values.reject(&:silent?)
              end

              def resonating_echoes
                @echoes.values.select(&:resonate?)
              end

              def chamber_by_id(chamber_id)
                @chambers[chamber_id]
              end

              def echo_by_id(echo_id)
                @echoes[echo_id]
              end

              private

              def prune_echoes
                return if @echoes.size < MAX_ECHOES

                silent = @echoes.values.select(&:silent?)
                silent.each { |e| @echoes.delete(e.id) }
                return unless @echoes.size >= MAX_ECHOES

                faintest = @echoes.values.min_by(&:amplitude)
                @echoes.delete(faintest.id) if faintest
              end

              def prune_chambers
                return if @chambers.size < MAX_CHAMBERS

                collapsed = @chambers.values.select { |c| c.state == :collapsed }
                collapsed.each { |c| @chambers.delete(c.id) }
              end

              def prune_silent_echoes
                @echoes.select { |_, e| e.silent? }.each_key { |id| @echoes.delete(id) }
              end

              def record_disruption(chamber_id:, force:, result:)
                @disruption_history << {
                  chamber_id:   chamber_id,
                  force:        force,
                  breakthrough: result[:breakthrough],
                  occurred_at:  Time.now.utc
                }
              end
            end
          end
        end
      end
    end
  end
end
