# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Memory
        module EchoChamber
          module Helpers
            class Chamber
              include Constants

              attr_reader :id, :label, :domain, :state, :wall_thickness,
                          :resonance_frequency, :created_at, :disruption_count

              def initialize(label:, domain: :general, wall_thickness: DEFAULT_WALL_THICKNESS)
                @id                  = SecureRandom.uuid
                @label               = label
                @domain              = domain.to_sym
                @state               = :forming
                @wall_thickness      = wall_thickness.to_f.clamp(0.0, 1.0).round(10)
                @resonance_frequency = 0.0
                @echoes              = {}
                @disruption_count    = 0
                @created_at          = Time.now.utc
              end

              def add_echo(echo)
                return false if @echoes.size >= MAX_ECHOES

                @echoes[echo.id] = echo
                recalculate_resonance
                update_state
                true
              end

              def remove_echo(echo_id)
                removed = @echoes.delete(echo_id)
                recalculate_resonance if removed
                update_state
                !removed.nil?
              end

              def amplify_all!(rate = AMPLIFICATION_RATE)
                @echoes.each_value { |e| e.amplify!(rate) }
                recalculate_resonance
                update_state
                { amplified: @echoes.size, resonance_frequency: @resonance_frequency }
              end

              def disrupt!(force)
                force = force.to_f.clamp(0.0, 1.0)
                return { success: false, reason: 'insufficient_force', force: force, wall: @wall_thickness } if force <= @wall_thickness

                @disruption_count += 1
                breakthrough = force - @wall_thickness
                @wall_thickness = (@wall_thickness - (breakthrough * BREAKTHROUGH_BONUS)).clamp(0.0, 1.0).round(10)
                @echoes.each_value { |e| e.dampen!(breakthrough.round(10)) }
                @state = :disrupted
                recalculate_resonance
                { success: true, force: force, breakthrough: breakthrough.round(10), wall_remaining: @wall_thickness }
              end

              def sealed?
                @wall_thickness >= SEALED_THRESHOLD
              end

              def porous?
                @wall_thickness <= POROUS_THRESHOLD
              end

              def resonance_level
                Constants.label_for(RESONANCE_LABELS, @resonance_frequency)
              end

              def echo_count
                @echoes.size
              end

              def active_echoes
                @echoes.values.reject(&:silent?)
              end

              def resonating_echoes
                @echoes.values.select(&:resonate?)
              end

              def to_h
                {
                  id:                  @id,
                  label:               @label,
                  domain:              @domain,
                  state:               @state,
                  wall_thickness:      @wall_thickness,
                  resonance_frequency: @resonance_frequency,
                  resonance_level:     resonance_level,
                  sealed:              sealed?,
                  porous:              porous?,
                  echo_count:          echo_count,
                  active_echo_count:   active_echoes.size,
                  disruption_count:    @disruption_count,
                  created_at:          @created_at
                }
              end

              private

              def recalculate_resonance
                return @resonance_frequency = 0.0 if @echoes.empty?

                resonating = resonating_echoes
                @resonance_frequency = (resonating.size.to_f / @echoes.size).round(10)
              end

              def update_state
                return if @state == :disrupted || @state == :collapsed
                return @state = :forming if @echoes.empty?

                @state = if @resonance_frequency >= DISRUPTION_THRESHOLD
                           :saturated
                         elsif @resonance_frequency >= POROUS_THRESHOLD
                           :resonating
                         else
                           :forming
                         end
              end
            end
          end
        end
      end
    end
  end
end
