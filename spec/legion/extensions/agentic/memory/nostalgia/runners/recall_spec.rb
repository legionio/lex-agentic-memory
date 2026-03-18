# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Nostalgia::Runners::Recall do
  let(:engine) { Legion::Extensions::Agentic::Memory::Nostalgia::Helpers::NostalgiaEngine.new }

  let(:client) do
    Class.new do
      include Legion::Extensions::Agentic::Memory::Nostalgia::Runners::Recall
    end.new
  end

  describe '#store_memory' do
    it 'returns success: true' do
      result = client.store_memory(content: 'old school', engine: engine)
      expect(result[:success]).to be true
    end

    it 'includes memory hash' do
      result = client.store_memory(content: 'old school', engine: engine)
      expect(result[:memory]).to include(:id, :content, :domain, :warmth)
    end

    it 'stores memory in engine' do
      client.store_memory(content: 'test memory', domain: :place, engine: engine)
      expect(engine.memories.size).to eq(1)
    end
  end

  describe '#trigger_nostalgia' do
    before do
      engine.create_memory(content: 'summer in the park', domain: :place, original_valence: 0.5)
    end

    it 'returns success: true' do
      result = client.trigger_nostalgia(trigger: 'summer', engine: engine)
      expect(result[:success]).to be true
    end

    it 'includes events array' do
      result = client.trigger_nostalgia(trigger: 'summer', engine: engine)
      expect(result[:events]).to be_an(Array)
    end

    it 'includes count' do
      result = client.trigger_nostalgia(trigger: 'summer', engine: engine)
      expect(result[:count]).to eq(result[:events].size)
    end
  end

  describe '#age_memories' do
    before do
      engine.create_memory(content: 'memory')
    end

    it 'returns success: true' do
      result = client.age_memories(engine: engine)
      expect(result[:success]).to be true
    end

    it 'includes memory_count' do
      result = client.age_memories(engine: engine)
      expect(result[:memory_count]).to eq(1)
    end
  end

  describe '#nostalgia_report' do
    before do
      engine.create_memory(content: 'report memory', warmth: 0.6, original_valence: 0.3)
    end

    it 'returns success: true' do
      result = client.nostalgia_report(engine: engine)
      expect(result[:success]).to be true
    end

    it 'includes report fields' do
      result = client.nostalgia_report(engine: engine)
      expect(result).to include(:total_memories, :rosy_retrospection_index, :nostalgia_proneness)
    end
  end
end
