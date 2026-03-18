# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::ImmuneMemory::Helpers::ImmuneMemoryEngine do
  subject(:engine) { described_class.new }

  describe '#create_memory_cell' do
    it 'creates and returns a cell' do
      cell = engine.create_memory_cell(threat_type: :prompt_injection, signature: 'sig-001')
      expect(cell.threat_type).to eq(:prompt_injection)
    end
  end

  describe '#vaccinate' do
    it 'creates a new cell for unknown signature' do
      cell = engine.vaccinate(threat_type: :data_poisoning, signature: 'vax-001')
      expect(cell.strength).to eq(0.5)
    end

    it 'activates existing cell for known signature' do
      engine.vaccinate(threat_type: :data_poisoning, signature: 'vax-001')
      cell = engine.vaccinate(threat_type: :data_poisoning, signature: 'vax-001')
      expect(cell.encounter_count).to eq(1)
    end
  end

  describe '#encounter_threat' do
    it 'returns a primary encounter for new threat' do
      record = engine.encounter_threat(threat_type: :prompt_injection, threat_signature: 'new-sig')
      expect(record.response_type).to eq(:primary)
    end

    it 'returns a secondary encounter for known threat' do
      engine.vaccinate(threat_type: :prompt_injection, signature: 'known-sig', strength: 0.7)
      record = engine.encounter_threat(threat_type: :prompt_injection, threat_signature: 'known-sig')
      expect(record.response_type).to eq(:secondary)
    end

    it 'creates a memory cell after first encounter' do
      engine.encounter_threat(threat_type: :social_engineering, threat_signature: 'first-sig')
      expect(engine.active_cells.size).to eq(1)
    end

    it 'neutralizes weak threats' do
      record = engine.encounter_threat(threat_type: :logic_manipulation, threat_signature: 'weak', severity: 0.3)
      expect(record.neutralized?).to be true
    end

    it 'may fail against strong threats without memory' do
      record = engine.encounter_threat(threat_type: :privilege_escalation, threat_signature: 'strong', severity: 0.9)
      expect(record.evaded?).to be true
    end

    it 'neutralizes strong threats with strong memory' do
      cell = engine.vaccinate(threat_type: :privilege_escalation, signature: 'strong', strength: 0.95)
      3.times { cell.activate! }
      record = engine.encounter_threat(threat_type: :privilege_escalation, threat_signature: 'strong', severity: 0.9)
      expect(record.neutralized?).to be true
    end
  end

  describe '#decay_all!' do
    it 'decays all cells' do
      engine.create_memory_cell(threat_type: :prompt_injection, signature: 's1')
      result = engine.decay_all!
      expect(result[:cells_remaining]).to be >= 0
    end
  end

  describe '#find_by_signature' do
    it 'finds matching cell' do
      engine.create_memory_cell(threat_type: :prompt_injection, signature: 'find-me')
      expect(engine.find_by_signature('find-me')).not_to be_nil
    end

    it 'returns nil for unknown signature' do
      expect(engine.find_by_signature('nope')).to be_nil
    end
  end

  describe '#cells_for_threat' do
    it 'filters by threat type' do
      engine.create_memory_cell(threat_type: :prompt_injection, signature: 's1')
      engine.create_memory_cell(threat_type: :data_poisoning, signature: 's2')
      expect(engine.cells_for_threat(threat_type: :prompt_injection).size).to eq(1)
    end
  end

  describe '#immunity_for' do
    it 'returns 0.0 for unknown threat type' do
      expect(engine.immunity_for(threat_type: :unknown_threat)).to eq(0.0)
    end

    it 'returns max strength for known threat' do
      engine.create_memory_cell(threat_type: :prompt_injection, signature: 's1', strength: 0.8)
      expect(engine.immunity_for(threat_type: :prompt_injection)).to eq(0.8)
    end
  end

  describe '#active_cells' do
    it 'excludes expired cells' do
      cell = engine.create_memory_cell(threat_type: :prompt_injection, signature: 's1', strength: 0.01)
      2.times { cell.decay! }
      expect(engine.active_cells).to be_empty
    end
  end

  describe '#t_cells' do
    it 'returns only t-type cells' do
      engine.create_memory_cell(threat_type: :prompt_injection, signature: 's1', cell_type: :t_killer)
      engine.create_memory_cell(threat_type: :data_poisoning, signature: 's2', cell_type: :b_memory)
      expect(engine.t_cells.size).to eq(1)
    end
  end

  describe '#b_cells' do
    it 'returns only b-type cells' do
      engine.create_memory_cell(threat_type: :prompt_injection, signature: 's1', cell_type: :t_killer)
      engine.create_memory_cell(threat_type: :data_poisoning, signature: 's2', cell_type: :b_plasma)
      expect(engine.b_cells.size).to eq(1)
    end
  end

  describe '#veteran_cells' do
    it 'returns cells with 5+ encounters' do
      cell = engine.create_memory_cell(threat_type: :prompt_injection, signature: 's1')
      5.times { cell.activate! }
      expect(engine.veteran_cells.size).to eq(1)
    end
  end

  describe '#naive_cells' do
    it 'returns cells with 0 encounters' do
      engine.create_memory_cell(threat_type: :prompt_injection, signature: 's1')
      expect(engine.naive_cells.size).to eq(1)
    end
  end

  describe '#secondary_response_rate' do
    it 'returns 0.0 with no encounters' do
      expect(engine.secondary_response_rate).to eq(0.0)
    end

    it 'calculates rate correctly' do
      engine.vaccinate(threat_type: :prompt_injection, signature: 'known', strength: 0.7)
      engine.encounter_threat(threat_type: :prompt_injection, threat_signature: 'known')
      engine.encounter_threat(threat_type: :data_poisoning, threat_signature: 'new')
      expect(engine.secondary_response_rate).to eq(0.5)
    end
  end

  describe '#neutralization_rate' do
    it 'returns 0.0 with no encounters' do
      expect(engine.neutralization_rate).to eq(0.0)
    end
  end

  describe '#average_response_speed' do
    it 'returns primary speed with no encounters' do
      expect(engine.average_response_speed).to eq(1.0)
    end
  end

  describe '#threat_coverage' do
    it 'returns 0.0 with no cells' do
      expect(engine.threat_coverage).to eq(0.0)
    end

    it 'increases with known threat types' do
      engine.create_memory_cell(threat_type: :prompt_injection, signature: 's1')
      engine.create_memory_cell(threat_type: :data_poisoning, signature: 's2')
      expect(engine.threat_coverage).to be > 0.0
    end
  end

  describe '#overall_health' do
    it 'returns 0.0 with no cells' do
      expect(engine.overall_health).to eq(0.0)
    end

    it 'returns positive with cells' do
      engine.create_memory_cell(threat_type: :prompt_injection, signature: 's1', strength: 0.8)
      expect(engine.overall_health).to be > 0.0
    end
  end

  describe '#immune_report' do
    it 'includes all report fields' do
      report = engine.immune_report
      expect(report).to include(
        :total_cells, :active_cells, :t_cells, :b_cells, :veteran_cells,
        :total_encounters, :secondary_response_rate, :neutralization_rate,
        :average_response_speed, :threat_coverage, :overall_health, :health_label
      )
    end
  end

  describe '#to_h' do
    it 'includes summary fields' do
      hash = engine.to_h
      expect(hash).to include(:total_cells, :active, :encounters, :health, :threat_coverage)
    end
  end
end
