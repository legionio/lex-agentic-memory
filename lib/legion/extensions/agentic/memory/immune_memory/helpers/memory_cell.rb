# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Memory
        module ImmuneMemory
          module Helpers
            class MemoryCell
              include Constants

              attr_reader :id, :threat_type, :signature, :cell_type, :created_at,
                          :encounter_count, :decay_cycles
              attr_accessor :strength

              def initialize(threat_type:, signature:, cell_type: :b_memory, strength: VACCINATION_STRENGTH)
                @id = SecureRandom.uuid
                @threat_type = threat_type.to_sym
                @signature = signature.to_s
                @cell_type = valid_cell_type(cell_type)
                @strength = strength.to_f.clamp(0.0, 1.0)
                @encounter_count = 0
                @decay_cycles = 0
                @created_at = Time.now
              end

              def activate!
                @encounter_count += 1
                boost = t_cell? ? T_CELL_BOOST : B_CELL_BOOST
                @strength = (@strength + boost).clamp(0.0, 1.0).round(10)
                @decay_cycles = 0
                self
              end

              def decay!
                @decay_cycles += 1
                rate = t_cell? ? T_CELL_DECAY : B_CELL_DECAY
                @strength = (@strength - rate).clamp(0.0, 1.0).round(10)
                self
              end

              def recognizes?(threat_signature)
                @signature == threat_signature.to_s && @strength >= MEMORY_RECOGNITION_THRESHOLD
              end

              def t_cell? = %i[t_helper t_killer].include?(@cell_type)
              def b_cell? = %i[b_memory b_plasma].include?(@cell_type)
              def expired? = @strength <= 0.0
              def veteran? = @encounter_count >= 5
              def naive? = @encounter_count.zero?
              def active? = @strength > T_CELL_ACTIVATION_THRESHOLD

              def response_speed
                return PRIMARY_RESPONSE_SPEED if naive?

                (PRIMARY_RESPONSE_SPEED + (@encounter_count * 0.4)).clamp(1.0, SECONDARY_RESPONSE_SPEED).round(10)
              end

              def maturity = (@encounter_count / 10.0).clamp(0.0, 1.0).round(10)
              def maturity_label = Constants.label_for(MATURITY_LABELS, maturity)
              def immunity_label = Constants.label_for(IMMUNITY_LABELS, @strength)
              def speed_label = Constants.label_for(RESPONSE_SPEED_LABELS, response_speed)

              def to_h
                {
                  id:              @id,
                  threat_type:     @threat_type,
                  signature:       @signature,
                  cell_type:       @cell_type,
                  strength:        @strength,
                  encounter_count: @encounter_count,
                  decay_cycles:    @decay_cycles,
                  response_speed:  response_speed,
                  immunity_label:  immunity_label,
                  maturity_label:  maturity_label,
                  t_cell:          t_cell?,
                  b_cell:          b_cell?,
                  expired:         expired?,
                  created_at:      @created_at.iso8601
                }
              end

              private

              def valid_cell_type(type)
                sym = type.to_sym
                CELL_TYPES.include?(sym) ? sym : :b_memory
              end
            end
          end
        end
      end
    end
  end
end
