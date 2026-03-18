# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Palimpsest::Helpers::BeliefLayer do
  subject(:layer) do
    described_class.new(content: 'the sky is blue', confidence: 0.8, domain: :factual)
  end

  describe '#initialize' do
    it 'sets content' do
      expect(layer.content).to eq('the sky is blue')
    end

    it 'sets confidence' do
      expect(layer.confidence).to eq(0.8)
    end

    it 'sets domain' do
      expect(layer.domain).to eq(:factual)
    end

    it 'generates a uuid id' do
      expect(layer.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets timestamp' do
      expect(layer.timestamp).to be_a(Time)
    end

    it 'is not superseded by default' do
      expect(layer.superseded_by).to be_nil
      expect(layer.superseded?).to be false
    end

    it 'clamps confidence above 1.0' do
      l = described_class.new(content: 'x', confidence: 1.5)
      expect(l.confidence).to eq(1.0)
    end

    it 'clamps confidence below 0.0' do
      l = described_class.new(content: 'x', confidence: -0.5)
      expect(l.confidence).to eq(0.0)
    end

    it 'defaults version to 1' do
      l = described_class.new(content: 'x')
      expect(l.version).to eq(1)
    end

    it 'defaults author to :system' do
      l = described_class.new(content: 'x')
      expect(l.author).to eq(:system)
    end
  end

  describe '#supersede!' do
    it 'sets superseded_by' do
      layer.supersede!('next-id')
      expect(layer.superseded_by).to eq('next-id')
      expect(layer.superseded?).to be true
    end
  end

  describe '#ghost?' do
    context 'when superseded with confidence above threshold' do
      it 'is a ghost' do
        layer.supersede!('x')
        expect(layer.ghost?).to be true
      end
    end

    context 'when not superseded' do
      it 'is not a ghost' do
        expect(layer.ghost?).to be false
      end
    end

    context 'when superseded with confidence at or below threshold' do
      it 'is not a ghost' do
        low = described_class.new(content: 'x', confidence: 0.05)
        low.supersede!('x')
        expect(low.ghost?).to be false
      end
    end
  end

  describe '#dissipated?' do
    it 'is dissipated when superseded and confidence at or below threshold' do
      low = described_class.new(content: 'x', confidence: 0.05)
      low.supersede!('x')
      expect(low.dissipated?).to be true
    end

    it 'is not dissipated when not superseded' do
      expect(layer.dissipated?).to be false
    end
  end

  describe '#erode!' do
    it 'reduces confidence by EROSION_RATE' do
      original = layer.confidence
      layer.erode!
      expect(layer.confidence).to be < original
    end

    it 'does not go below 0.0' do
      low = described_class.new(content: 'x', confidence: 0.02)
      low.erode!(rate: 0.1)
      expect(low.confidence).to eq(0.0)
    end

    it 'accepts a custom rate' do
      layer.erode!(rate: 0.1)
      expect(layer.confidence).to be_within(0.001).of(0.7)
    end
  end

  describe '#confidence_label' do
    it 'returns :high for 0.8' do
      expect(layer.confidence_label).to eq(:high)
    end

    it 'returns :ghost for very low confidence' do
      l = described_class.new(content: 'x', confidence: 0.05)
      expect(l.confidence_label).to eq(:ghost)
    end
  end

  describe '#ghost_label' do
    it 'returns :not_ghost when not superseded' do
      expect(layer.ghost_label).to eq(:not_ghost)
    end

    it 'returns :strong_ghost when superseded with high confidence' do
      layer.supersede!('x')
      expect(layer.ghost_label).to eq(:strong_ghost)
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      h = layer.to_h
      expect(h).to include(:id, :content, :confidence, :domain, :version, :author,
                           :timestamp, :superseded_by, :superseded, :ghost, :label)
    end

    it 'rounds confidence to 4 decimal places' do
      expect(layer.to_h[:confidence]).to eq(0.8)
    end
  end
end
