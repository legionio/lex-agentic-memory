# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module ImmuneMemory
          module Helpers
            class ImmuneMemoryEngine
              include Constants

              def initialize
                @memory_cells = {}
                @encounters = []
              end

              def create_memory_cell(threat_type:, signature:, cell_type: :b_memory, strength: VACCINATION_STRENGTH)
                prune_expired
                cell = MemoryCell.new(threat_type: threat_type, signature: signature,
                                      cell_type: cell_type, strength: strength)
                @memory_cells[cell.id] = cell
                cell
              end

              def vaccinate(threat_type:, signature:, strength: VACCINATION_STRENGTH)
                existing = find_by_signature(signature)
                return existing.activate! if existing

                create_memory_cell(threat_type: threat_type, signature: signature,
                                   cell_type: :b_memory, strength: strength)
              end

              def encounter_threat(threat_type:, threat_signature:, severity: 0.5)
                matching = find_by_signature(threat_signature)
                response_type = matching ? :secondary : :primary
                speed = matching ? matching.response_speed : PRIMARY_RESPONSE_SPEED
                outcome = determine_outcome(matching, severity)

                matching&.activate!

                record = Encounter.new(
                  threat_type: threat_type, threat_signature: threat_signature,
                  severity: severity, response_type: response_type,
                  response_speed: speed, outcome: outcome
                )
                @encounters << record
                prune_encounters

                unless matching
                  create_memory_cell(threat_type: threat_type, signature: threat_signature,
                                     cell_type: :b_memory, strength: B_CELL_ACTIVATION_THRESHOLD)
                end

                record
              end

              def decay_all!
                @memory_cells.each_value(&:decay!)
                prune_expired
                { cells_remaining: @memory_cells.size }
              end

              def find_by_signature(signature)
                @memory_cells.values.find { |c| c.signature == signature.to_s && !c.expired? }
              end

              def cells_for_threat(threat_type:)
                @memory_cells.values.select { |c| c.threat_type == threat_type.to_sym && !c.expired? }
              end

              def immunity_for(threat_type:)
                cells = cells_for_threat(threat_type: threat_type)
                return 0.0 if cells.empty?

                cells.max_by(&:strength).strength
              end

              def active_cells = @memory_cells.values.reject(&:expired?)
              def t_cells = @memory_cells.values.select(&:t_cell?)
              def b_cells = @memory_cells.values.select(&:b_cell?)
              def veteran_cells = @memory_cells.values.select(&:veteran?)
              def naive_cells = @memory_cells.values.select(&:naive?)

              def encounters_for(threat_type:)
                @encounters.select { |e| e.threat_type == threat_type.to_sym }
              end

              def secondary_response_rate
                return 0.0 if @encounters.empty?

                secondary = @encounters.count(&:secondary?)
                (secondary.to_f / @encounters.size).round(10)
              end

              def neutralization_rate
                return 0.0 if @encounters.empty?

                neutralized = @encounters.count(&:neutralized?)
                (neutralized.to_f / @encounters.size).round(10)
              end

              def average_response_speed
                return PRIMARY_RESPONSE_SPEED if @encounters.empty?

                (@encounters.sum(&:response_speed) / @encounters.size).round(10)
              end

              def threat_coverage
                known_types = @memory_cells.values.map(&:threat_type).uniq
                (known_types.size.to_f / THREAT_TYPES.size).clamp(0.0, 1.0).round(10)
              end

              def overall_health
                return 0.0 if @memory_cells.empty?

                avg_strength = (@memory_cells.values.sum(&:strength) / @memory_cells.size).round(10)
                coverage_factor = threat_coverage
                ((avg_strength * 0.6) + (coverage_factor * 0.4)).clamp(0.0, 1.0).round(10)
              end

              def health_label = Constants.label_for(HEALTH_LABELS, overall_health)

              def immune_report
                {
                  total_cells:             @memory_cells.size,
                  active_cells:            active_cells.size,
                  t_cells:                 t_cells.size,
                  b_cells:                 b_cells.size,
                  veteran_cells:           veteran_cells.size,
                  total_encounters:        @encounters.size,
                  secondary_response_rate: secondary_response_rate,
                  neutralization_rate:     neutralization_rate,
                  average_response_speed:  average_response_speed,
                  threat_coverage:         threat_coverage,
                  overall_health:          overall_health,
                  health_label:            health_label
                }
              end

              def to_h
                {
                  total_cells:     @memory_cells.size,
                  active:          active_cells.size,
                  encounters:      @encounters.size,
                  health:          overall_health,
                  threat_coverage: threat_coverage
                }
              end

              private

              def determine_outcome(matching_cell, severity)
                return :neutralized if matching_cell && matching_cell.strength >= severity

                severity < 0.5 ? :neutralized : :evaded
              end

              def prune_expired
                @memory_cells.reject! { |_, c| c.expired? } if @memory_cells.size >= MAX_MEMORY_CELLS
              end

              def prune_encounters
                @encounters.shift while @encounters.size > MAX_ENCOUNTERS
              end
            end
          end
        end
      end
    end
  end
end
