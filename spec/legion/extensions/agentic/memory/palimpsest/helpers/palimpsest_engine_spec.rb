# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Palimpsest::Helpers::PalimpsestEngine do
  subject(:engine) { described_class.new }

  describe '#create' do
    it 'creates a new palimpsest' do
      p = engine.create(topic: 'gravity', domain: :factual)
      expect(p).not_to be_nil
      expect(p.topic).to eq('gravity')
    end

    it 'returns nil for duplicate topic' do
      engine.create(topic: 'gravity')
      expect(engine.create(topic: 'gravity')).to be_nil
    end

    it 'stores in palimpsests hash' do
      engine.create(topic: 'light')
      expect(engine.palimpsests).to have_key('light')
    end
  end

  describe '#overwrite' do
    it 'creates and overwrites in one call' do
      layer = engine.overwrite(topic: 'sky', content: 'blue', confidence: 0.8)
      expect(layer).not_to be_nil
      expect(layer.content).to eq('blue')
    end

    it 'overwrites an existing palimpsest' do
      engine.overwrite(topic: 'sky', content: 'v1', confidence: 0.7)
      engine.overwrite(topic: 'sky', content: 'v2', confidence: 0.9)
      expect(engine.palimpsests['sky'].current_layer.content).to eq('v2')
    end
  end

  describe '#peek_through' do
    it 'returns previous layers as hashes' do
      engine.overwrite(topic: 'x', content: 'old')
      engine.overwrite(topic: 'x', content: 'new')
      layers = engine.peek_through(topic: 'x', depth: 1)
      expect(layers.first[:content]).to eq('old')
    end

    it 'returns empty for unknown topic' do
      expect(engine.peek_through(topic: 'unknown')).to eq([])
    end
  end

  describe '#erode' do
    it 'reduces confidence' do
      engine.overwrite(topic: 'y', content: 'content', confidence: 0.8)
      result = engine.erode(topic: 'y')
      expect(result).to be < 0.8
    end

    it 'returns nil for unknown topic' do
      expect(engine.erode(topic: 'missing')).to be_nil
    end
  end

  describe '#ghost_layers_for' do
    it 'returns ghost layers as hashes' do
      engine.overwrite(topic: 'z', content: 'v1', confidence: 0.8)
      engine.overwrite(topic: 'z', content: 'v2')
      layers = engine.ghost_layers_for(topic: 'z')
      expect(layers.size).to eq(1)
      expect(layers.first).to be_a(Hash)
    end

    it 'returns empty for unknown topic' do
      expect(engine.ghost_layers_for(topic: 'missing')).to eq([])
    end
  end

  describe '#all_ghost_layers' do
    it 'aggregates ghosts across all palimpsests' do
      engine.overwrite(topic: 'a', content: 'v1', confidence: 0.8)
      engine.overwrite(topic: 'a', content: 'v2')
      engine.overwrite(topic: 'b', content: 'v1', confidence: 0.7)
      engine.overwrite(topic: 'b', content: 'v2')
      expect(engine.all_ghost_layers.size).to eq(2)
    end
  end

  describe '#domain_archaeology' do
    it 'returns all layers for a given domain' do
      engine.create(topic: 'a', domain: :factual)
      engine.overwrite(topic: 'a', content: 'v1')
      engine.overwrite(topic: 'a', content: 'v2')
      engine.create(topic: 'b', domain: :emotional)
      engine.overwrite(topic: 'b', content: 'feeling')
      layers = engine.domain_archaeology(domain: :factual)
      expect(layers.size).to eq(2)
      expect(layers.all? { |l| l[:topic] == 'a' }).to be true
    end
  end

  describe '#belief_drift' do
    it 'returns drift hash' do
      engine.overwrite(topic: 'drift', content: 'v1', confidence: 0.3)
      engine.overwrite(topic: 'drift', content: 'v2', confidence: 0.9)
      result = engine.belief_drift(topic: 'drift')
      expect(result[:drift]).to be > 0
      expect(result[:label]).to be_a(Symbol)
    end

    it 'returns nil for unknown topic' do
      expect(engine.belief_drift(topic: 'unknown')).to be_nil
    end
  end

  describe '#overwrite_frequency' do
    it 'returns count of overwrites' do
      engine.overwrite(topic: 'freq', content: 'v1')
      engine.overwrite(topic: 'freq', content: 'v2')
      engine.overwrite(topic: 'freq', content: 'v3')
      expect(engine.overwrite_frequency(topic: 'freq')).to eq(3)
    end

    it 'returns nil for unknown topic' do
      expect(engine.overwrite_frequency(topic: 'missing')).to be_nil
    end
  end

  describe '#most_rewritten' do
    it 'returns palimpsests sorted by overwrite count descending' do
      3.times { engine.overwrite(topic: 'many', content: "v#{it}") }
      engine.overwrite(topic: 'few', content: 'v1')
      result = engine.most_rewritten(limit: 2)
      expect(result.first[:topic]).to eq('many')
    end

    it 'respects limit' do
      5.times { |i| engine.overwrite(topic: "t#{i}", content: 'x') }
      expect(engine.most_rewritten(limit: 3).size).to eq(3)
    end
  end

  describe '#decay_all!' do
    it 'decays ghost layers without raising' do
      engine.overwrite(topic: 'g', content: 'v1', confidence: 0.8)
      engine.overwrite(topic: 'g', content: 'v2')
      old_conf = engine.palimpsests['g'].historical_layers.first.confidence
      engine.decay_all!
      expect(engine.palimpsests['g'].historical_layers.first.confidence).to be < old_conf
    end
  end

  describe '#palimpsest_report' do
    it 'returns report hash' do
      engine.overwrite(topic: 'r1', content: 'v1', confidence: 0.8)
      engine.overwrite(topic: 'r1', content: 'v2')
      report = engine.palimpsest_report
      expect(report).to include(:palimpsest_count, :total_ghosts, :average_drift, :most_rewritten)
      expect(report[:palimpsest_count]).to eq(1)
    end

    it 'returns zero average_drift for empty engine' do
      expect(engine.palimpsest_report[:average_drift]).to eq(0.0)
    end
  end
end
