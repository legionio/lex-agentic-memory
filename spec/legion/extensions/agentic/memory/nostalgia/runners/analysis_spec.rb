# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Nostalgia::Runners::Analysis do
  let(:engine) { Legion::Extensions::Agentic::Memory::Nostalgia::Helpers::NostalgiaEngine.new }

  let(:client) do
    Class.new do
      include Legion::Extensions::Agentic::Memory::Nostalgia::Runners::Analysis
    end.new
  end

  before do
    engine.create_memory(content: 'great vacation', domain: :place, warmth: 0.8, original_valence: 0.4)
    engine.create_memory(content: 'promotion day', domain: :achievement, warmth: 0.6, original_valence: 0.7)
    engine.create_memory(content: 'tough breakup', domain: :relationship, warmth: 0.7, original_valence: 0.2)
  end

  describe '#warmth_by_domain' do
    it 'returns success: true' do
      result = client.warmth_by_domain(engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns warmth_by_domain hash' do
      result = client.warmth_by_domain(engine: engine)
      expect(result[:warmth_by_domain]).to be_a(Hash)
      expect(result[:warmth_by_domain]).to have_key(:place)
    end
  end

  describe '#rosy_retrospection_index' do
    it 'returns success: true' do
      result = client.rosy_retrospection_index(engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns index in [0, 1]' do
      result = client.rosy_retrospection_index(engine: engine)
      expect(result[:index]).to be_between(0.0, 1.0)
    end

    it 'returns a retrospection label' do
      result = client.rosy_retrospection_index(engine: engine)
      expect(result[:label]).to be_a(Symbol)
    end
  end

  describe '#nostalgia_proneness' do
    it 'returns success: true' do
      result = client.nostalgia_proneness(engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns proneness in [0, 1]' do
      result = client.nostalgia_proneness(engine: engine)
      expect(result[:proneness]).to be_between(0.0, 1.0)
    end

    it 'returns a nostalgia label' do
      result = client.nostalgia_proneness(engine: engine)
      expect(result[:label]).to be_a(Symbol)
    end
  end

  describe '#most_nostalgic_domains' do
    it 'returns success: true' do
      result = client.most_nostalgic_domains(engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns sorted domains' do
      result = client.most_nostalgic_domains(engine: engine)
      domains = result[:domains]
      expect(domains).to be_an(Array)
      expect(domains.first[:avg_warmth]).to be >= domains.last[:avg_warmth]
    end
  end

  describe '#bittersweet_memories' do
    it 'returns success: true' do
      result = client.bittersweet_memories(engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns only bittersweet memories' do
      result = client.bittersweet_memories(engine: engine)
      expect(result[:memories]).to be_an(Array)
      expect(result[:count]).to eq(result[:memories].size)
    end

    it 'identifies the tough breakup as bittersweet' do
      result = client.bittersweet_memories(engine: engine)
      contents = result[:memories].map { |m| m[:content] }
      expect(contents).to include('tough breakup')
    end
  end
end
