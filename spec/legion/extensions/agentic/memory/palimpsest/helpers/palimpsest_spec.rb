# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Palimpsest::Helpers::Palimpsest do
  subject(:pal) { described_class.new(topic: 'weather', domain: :factual) }

  describe '#initialize' do
    it 'sets topic and domain' do
      expect(pal.topic).to eq('weather')
      expect(pal.domain).to eq(:factual)
    end

    it 'starts with no layers' do
      expect(pal.current_layer).to be_nil
      expect(pal.historical_layers).to be_empty
    end

    it 'starts with overwrite_count of 0' do
      expect(pal.overwrite_count).to eq(0)
    end

    it 'generates an id' do
      expect(pal.id).to match(/\A[0-9a-f-]{36}\z/)
    end
  end

  describe '#overwrite!' do
    it 'sets the current layer on first call' do
      layer = pal.overwrite!('it will rain', confidence: 0.7)
      expect(pal.current_layer).to eq(layer)
      expect(pal.current_layer.content).to eq('it will rain')
    end

    it 'increments overwrite_count' do
      pal.overwrite!('v1')
      pal.overwrite!('v2')
      expect(pal.overwrite_count).to eq(2)
    end

    it 'moves current to historical on second write' do
      pal.overwrite!('v1')
      pal.overwrite!('v2')
      expect(pal.historical_layers.size).to eq(1)
      expect(pal.historical_layers.first.content).to eq('v1')
    end

    it 'marks the old layer as superseded' do
      pal.overwrite!('v1')
      v1 = pal.current_layer
      pal.overwrite!('v2')
      expect(v1.superseded?).to be true
    end

    it 'increments layer version' do
      pal.overwrite!('v1')
      pal.overwrite!('v2')
      expect(pal.current_layer.version).to eq(2)
    end
  end

  describe '#peek_through' do
    before do
      pal.overwrite!('v1')
      pal.overwrite!('v2')
      pal.overwrite!('v3')
    end

    it 'returns the most recent historical layer by default' do
      layers = pal.peek_through(depth: 1)
      expect(layers.size).to eq(1)
      expect(layers.first.content).to eq('v2')
    end

    it 'returns multiple historical layers' do
      layers = pal.peek_through(depth: 2)
      expect(layers.size).to eq(2)
    end

    it 'returns empty when no history' do
      fresh = described_class.new(topic: 'new')
      expect(fresh.peek_through).to be_empty
    end

    it 'does not exceed available history' do
      layers = pal.peek_through(depth: 100)
      expect(layers.size).to eq(2)
    end
  end

  describe '#erode_current!' do
    it 'reduces confidence of current layer' do
      pal.overwrite!('content', confidence: 0.8)
      original = pal.current_layer.confidence
      pal.erode_current!
      expect(pal.current_layer.confidence).to be < original
    end

    it 'returns nil when no current layer' do
      expect(pal.erode_current!).to be_nil
    end
  end

  describe '#ghost_layers' do
    it 'returns superseded layers with confidence above threshold' do
      pal.overwrite!('v1', confidence: 0.8)
      pal.overwrite!('v2')
      expect(pal.ghost_layers.size).to eq(1)
    end

    it 'excludes dissipated layers' do
      pal.overwrite!('v1', confidence: 0.05)
      pal.overwrite!('v2')
      expect(pal.ghost_layers).to be_empty
    end
  end

  describe '#restoration_strength' do
    it 'returns 0.0 with no ghosts' do
      pal.overwrite!('v1')
      expect(pal.restoration_strength).to eq(0.0)
    end

    it 'returns average ghost confidence' do
      pal.overwrite!('v1', confidence: 0.8)
      pal.overwrite!('v2', confidence: 0.6)
      pal.overwrite!('v3')
      strength = pal.restoration_strength
      expect(strength).to be > 0.0
    end
  end

  describe '#belief_drift' do
    it 'returns 0.0 with no history' do
      pal.overwrite!('v1', confidence: 0.7)
      expect(pal.belief_drift).to eq(0.0)
    end

    it 'measures distance from origin to current' do
      pal.overwrite!('v1', confidence: 0.3)
      pal.overwrite!('v2', confidence: 0.8)
      expect(pal.belief_drift).to be_within(0.01).of(0.5)
    end
  end

  describe '#drift_label' do
    it 'returns a symbol' do
      pal.overwrite!('v1', confidence: 0.3)
      pal.overwrite!('v2', confidence: 0.9)
      expect(pal.drift_label).to be_a(Symbol)
    end
  end

  describe '#decay_ghosts!' do
    it 'erodes all historical layers' do
      pal.overwrite!('v1', confidence: 0.8)
      pal.overwrite!('v2')
      old_conf = pal.historical_layers.first.confidence
      pal.decay_ghosts!
      expect(pal.historical_layers.first.confidence).to be < old_conf
    end
  end

  describe '#to_h' do
    before { pal.overwrite!('v1') }

    it 'returns expected keys' do
      h = pal.to_h
      expect(h).to include(:id, :topic, :domain, :layer_count, :overwrite_count,
                           :ghost_count, :restoration_strength, :belief_drift,
                           :drift_label, :current_layer, :created_at)
    end
  end
end
