# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Reserve::Client do
  subject(:client) { described_class.new }

  describe '#add_cognitive_pathway' do
    it 'delegates to runner' do
      result = client.add_cognitive_pathway(function: :reasoning)
      expect(result[:success]).to be true
    end
  end

  describe '#damage_cognitive_pathway' do
    it 'damages and reports state' do
      pathway = client.add_cognitive_pathway(function: :test)
      result = client.damage_cognitive_pathway(pathway_id: pathway[:pathway_id], amount: 0.3)
      expect(result[:state]).to eq(:healthy)
    end
  end

  describe '#cognitive_reserve_stats' do
    it 'returns stats' do
      result = client.cognitive_reserve_stats
      expect(result[:success]).to be true
      expect(result[:pathway_count]).to eq(0)
    end
  end

  describe 'with injected engine' do
    it 'uses the provided engine' do
      engine = Legion::Extensions::Agentic::Memory::Reserve::Helpers::ReserveEngine.new
      engine.add_pathway(function: :preloaded)
      custom_client = described_class.new(engine: engine)
      expect(custom_client.cognitive_reserve_stats[:pathway_count]).to eq(1)
    end
  end
end
