# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::ImmuneMemory::Runners::CognitiveImmuneMemory do
  let(:engine) { Legion::Extensions::Agentic::Memory::ImmuneMemory::Helpers::ImmuneMemoryEngine.new }
  let(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj.instance_variable_set(:@default_engine, engine)
    obj
  end

  describe '#create_memory_cell' do
    it 'returns success with cell hash' do
      result = runner.create_memory_cell(threat_type: :prompt_injection, signature: 'sig-001', engine: engine)
      expect(result[:success]).to be true
      expect(result[:cell][:threat_type]).to eq(:prompt_injection)
    end
  end

  describe '#vaccinate' do
    it 'returns success' do
      result = runner.vaccinate(threat_type: :data_poisoning, signature: 'vax-001', engine: engine)
      expect(result[:success]).to be true
    end
  end

  describe '#encounter_threat' do
    it 'returns success with encounter hash' do
      result = runner.encounter_threat(threat_type: :prompt_injection, threat_signature: 'new', engine: engine)
      expect(result[:success]).to be true
      expect(result[:encounter][:response_type]).to eq(:primary)
    end
  end

  describe '#decay_all' do
    it 'returns success' do
      result = runner.decay_all(engine: engine)
      expect(result[:success]).to be true
    end
  end

  describe '#immunity_for' do
    it 'returns immunity level' do
      engine.create_memory_cell(threat_type: :prompt_injection, signature: 's1', strength: 0.8)
      result = runner.immunity_for(threat_type: :prompt_injection, engine: engine)
      expect(result[:success]).to be true
      expect(result[:immunity]).to eq(0.8)
    end
  end

  describe '#active_cells' do
    it 'returns cell list' do
      engine.create_memory_cell(threat_type: :prompt_injection, signature: 's1')
      result = runner.active_cells(engine: engine)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
    end
  end

  describe '#veteran_cells' do
    it 'returns veteran list' do
      result = runner.veteran_cells(engine: engine)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end
  end

  describe '#threat_coverage' do
    it 'returns coverage' do
      result = runner.threat_coverage(engine: engine)
      expect(result[:success]).to be true
      expect(result[:coverage]).to eq(0.0)
    end
  end

  describe '#immune_status' do
    it 'returns comprehensive status' do
      result = runner.immune_status(engine: engine)
      expect(result[:success]).to be true
      expect(result).to include(:total_cells, :overall_health)
    end
  end
end
