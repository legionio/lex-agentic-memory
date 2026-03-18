# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Palimpsest::Runners::CognitivePalimpsest do
  let(:engine) { Legion::Extensions::Agentic::Memory::Palimpsest::Helpers::PalimpsestEngine.new }
  let(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe '#create_palimpsest' do
    it 'creates a palimpsest' do
      result = runner.create_palimpsest(topic: 'memory', domain: :factual)
      expect(result[:success]).to be true
      expect(result[:topic]).to eq('memory')
    end

    it 'returns failure for duplicate topic' do
      runner.create_palimpsest(topic: 'dupe')
      result = runner.create_palimpsest(topic: 'dupe')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:limit_or_duplicate)
    end
  end

  describe '#overwrite_belief' do
    it 'overwrites a belief' do
      result = runner.overwrite_belief(topic: 'sky', content: 'blue', confidence: 0.8)
      expect(result[:success]).to be true
      expect(result[:version]).to eq(1)
      expect(result[:confidence]).to eq(0.8)
    end

    it 'increments version on subsequent writes' do
      runner.overwrite_belief(topic: 'sky', content: 'v1')
      result = runner.overwrite_belief(topic: 'sky', content: 'v2')
      expect(result[:version]).to eq(2)
    end

    it 'accepts custom engine' do
      result = runner.overwrite_belief(topic: 'x', content: 'y', engine: engine)
      expect(result[:success]).to be true
      expect(engine.palimpsests).to have_key('x')
    end
  end

  describe '#peek_through_belief' do
    it 'returns previous layers' do
      runner.overwrite_belief(topic: 'p', content: 'v1')
      runner.overwrite_belief(topic: 'p', content: 'v2')
      result = runner.peek_through_belief(topic: 'p', depth: 1)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
      expect(result[:layers].first[:content]).to eq('v1')
    end

    it 'returns empty for topic with no history' do
      runner.overwrite_belief(topic: 'fresh', content: 'v1')
      result = runner.peek_through_belief(topic: 'fresh')
      expect(result[:count]).to eq(0)
    end
  end

  describe '#erode_belief' do
    it 'erodes current layer confidence' do
      runner.overwrite_belief(topic: 'e', content: 'x', confidence: 0.8)
      result = runner.erode_belief(topic: 'e')
      expect(result[:success]).to be true
      expect(result[:confidence]).to be < 0.8
    end

    it 'returns failure for unknown topic' do
      result = runner.erode_belief(topic: 'missing')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#ghost_layers' do
    it 'returns ghost layers for topic' do
      runner.overwrite_belief(topic: 'g', content: 'v1', confidence: 0.8)
      runner.overwrite_belief(topic: 'g', content: 'v2')
      result = runner.ghost_layers(topic: 'g')
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
    end
  end

  describe '#all_ghost_layers' do
    it 'aggregates ghosts from all palimpsests' do
      runner.overwrite_belief(topic: 'a', content: 'v1', confidence: 0.8)
      runner.overwrite_belief(topic: 'a', content: 'v2')
      result = runner.all_ghost_layers
      expect(result[:success]).to be true
      expect(result[:count]).to be >= 1
    end
  end

  describe '#domain_archaeology' do
    it 'returns all layers for domain' do
      runner.create_palimpsest(topic: 'arch', domain: :procedural)
      runner.overwrite_belief(topic: 'arch', content: 'v1')
      runner.overwrite_belief(topic: 'arch', content: 'v2')
      result = runner.domain_archaeology(domain: :procedural)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(2)
    end
  end

  describe '#belief_drift' do
    it 'returns drift info' do
      runner.overwrite_belief(topic: 'd', content: 'v1', confidence: 0.2)
      runner.overwrite_belief(topic: 'd', content: 'v2', confidence: 0.9)
      result = runner.belief_drift(topic: 'd')
      expect(result[:success]).to be true
      expect(result[:drift]).to be > 0
    end

    it 'returns failure for unknown topic' do
      result = runner.belief_drift(topic: 'ghost_topic')
      expect(result[:success]).to be false
    end
  end

  describe '#overwrite_frequency' do
    it 'returns overwrite count' do
      3.times { |i| runner.overwrite_belief(topic: 'freq', content: "v#{i}") }
      result = runner.overwrite_frequency(topic: 'freq')
      expect(result[:success]).to be true
      expect(result[:overwrite_count]).to eq(3)
    end

    it 'returns failure for unknown topic' do
      result = runner.overwrite_frequency(topic: 'missing')
      expect(result[:success]).to be false
    end
  end

  describe '#most_rewritten' do
    it 'returns sorted list' do
      3.times { runner.overwrite_belief(topic: 'hot', content: "v#{it}") }
      runner.overwrite_belief(topic: 'cold', content: 'v1')
      result = runner.most_rewritten(limit: 2)
      expect(result[:success]).to be true
      expect(result[:palimpsests].first[:topic]).to eq('hot')
    end
  end

  describe '#decay_all_ghosts' do
    it 'returns success' do
      result = runner.decay_all_ghosts
      expect(result[:success]).to be true
    end
  end

  describe '#palimpsest_report' do
    it 'returns report with expected keys' do
      runner.overwrite_belief(topic: 'rep', content: 'v1', confidence: 0.8)
      runner.overwrite_belief(topic: 'rep', content: 'v2')
      result = runner.palimpsest_report
      expect(result[:success]).to be true
      expect(result).to include(:palimpsest_count, :total_ghosts, :average_drift)
    end
  end
end
