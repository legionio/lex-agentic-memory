# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module ImmuneMemory
          module Runners
            module CognitiveImmuneMemory
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def create_memory_cell(threat_type:, signature:, cell_type: :b_memory, strength: nil, engine: nil, **)
                eng = engine || @default_engine
                cell = eng.create_memory_cell(threat_type: threat_type, signature: signature,
                                              cell_type: cell_type,
                                              strength: strength || Helpers::Constants::VACCINATION_STRENGTH)
                { success: true, cell: cell.to_h }
              end

              def vaccinate(threat_type:, signature:, strength: nil, engine: nil, **)
                eng = engine || @default_engine
                cell = eng.vaccinate(threat_type: threat_type, signature: signature,
                                     strength: strength || Helpers::Constants::VACCINATION_STRENGTH)
                { success: true, cell: cell.to_h }
              end

              def encounter_threat(threat_type:, threat_signature:, severity: 0.5, engine: nil, **)
                eng = engine || @default_engine
                record = eng.encounter_threat(threat_type: threat_type, threat_signature: threat_signature,
                                              severity: severity)
                { success: true, encounter: record.to_h }
              end

              def decay_all(engine: nil, **)
                eng = engine || @default_engine
                result = eng.decay_all!
                { success: true, **result }
              end

              def immunity_for(threat_type:, engine: nil, **)
                eng = engine || @default_engine
                immunity = eng.immunity_for(threat_type: threat_type)
                label = Helpers::Constants.label_for(Helpers::Constants::IMMUNITY_LABELS, immunity)
                { success: true, threat_type: threat_type, immunity: immunity, label: label }
              end

              def active_cells(engine: nil, **)
                eng = engine || @default_engine
                cells = eng.active_cells
                { success: true, count: cells.size, cells: cells.map(&:to_h) }
              end

              def veteran_cells(engine: nil, **)
                eng = engine || @default_engine
                cells = eng.veteran_cells
                { success: true, count: cells.size, cells: cells.map(&:to_h) }
              end

              def threat_coverage(engine: nil, **)
                eng = engine || @default_engine
                coverage = eng.threat_coverage
                { success: true, coverage: coverage }
              end

              def immune_status(engine: nil, **)
                eng = engine || @default_engine
                report = eng.immune_report
                { success: true, **report }
              end
            end
          end
        end
      end
    end
  end
end
