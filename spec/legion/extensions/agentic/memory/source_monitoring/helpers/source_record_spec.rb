# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::SourceMonitoring::Helpers::SourceRecord do
  subject(:rec) do
    described_class.new(id: :src_one, content_id: 'fact:sky_blue', source: :external_perception)
  end

  let(:constants) { Legion::Extensions::Agentic::Memory::SourceMonitoring::Helpers::Constants }

  describe '#initialize' do
    it 'sets id, content_id, and source' do
      expect(rec.id).to eq(:src_one)
      expect(rec.content_id).to eq('fact:sky_blue')
      expect(rec.source).to eq(:external_perception)
    end

    it 'uses default confidence' do
      expect(rec.confidence).to eq(constants::DEFAULT_CONFIDENCE)
    end

    it 'starts unverified' do
      expect(rec.verified).to be false
    end
  end

  describe '#reality_status' do
    it 'returns :real for external perception' do
      expect(rec.reality_status).to eq(:real)
    end

    it 'returns :constructed for internal generation' do
      r = described_class.new(id: :x, content_id: :y, source: :internal_generation)
      expect(r.reality_status).to eq(:constructed)
    end

    it 'returns :imagined for imagination' do
      r = described_class.new(id: :x, content_id: :y, source: :imagination)
      expect(r.reality_status).to eq(:imagined)
    end
  end

  describe '#external? and #internal?' do
    it 'external_perception is external' do
      expect(rec.external?).to be true
      expect(rec.internal?).to be false
    end

    it 'imagination is internal' do
      r = described_class.new(id: :x, content_id: :y, source: :imagination)
      expect(r.internal?).to be true
      expect(r.external?).to be false
    end

    it 'inference is neither external nor internal' do
      r = described_class.new(id: :x, content_id: :y, source: :inference)
      expect(r.external?).to be false
      expect(r.internal?).to be false
    end
  end

  describe '#verify' do
    it 'marks as verified' do
      rec.verify
      expect(rec.verified).to be true
    end

    it 'boosts confidence' do
      before = rec.confidence
      rec.verify
      expect(rec.confidence).to be > before
    end
  end

  describe '#correct' do
    it 'changes source' do
      rec.correct(new_source: :memory_retrieval)
      expect(rec.source).to eq(:memory_retrieval)
    end

    it 'reduces confidence' do
      before = rec.confidence
      rec.correct(new_source: :memory_retrieval)
      expect(rec.confidence).to be < before
    end

    it 'increments correction count' do
      rec.correct(new_source: :memory_retrieval)
      expect(rec.correction_count).to eq(1)
    end
  end

  describe '#confused?' do
    it 'returns true when source is in confusion pair and low confidence' do
      rec.confidence = 0.3
      expect(rec.confused?).to be true
    end

    it 'returns false with high confidence' do
      rec.confidence = 0.8
      expect(rec.confused?).to be false
    end
  end

  describe '#decay' do
    it 'reduces confidence' do
      before = rec.confidence
      rec.decay
      expect(rec.confidence).to be < before
    end

    it 'respects floor' do
      100.times { rec.decay }
      expect(rec.confidence).to be >= constants::CONFIDENCE_FLOOR
    end
  end

  describe '#faded?' do
    it 'returns false initially' do
      expect(rec.faded?).to be false
    end

    it 'returns true at floor when unverified' do
      rec.confidence = constants::CONFIDENCE_FLOOR
      expect(rec.faded?).to be true
    end

    it 'returns false at floor when verified' do
      rec.verify
      rec.confidence = constants::CONFIDENCE_FLOOR
      expect(rec.faded?).to be false
    end
  end

  describe '#confidence_label' do
    it 'returns a symbol' do
      expect(rec.confidence_label).to be_a(Symbol)
    end

    it 'returns :confident for default confidence' do
      expect(rec.confidence_label).to eq(:confident)
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      h = rec.to_h
      expect(h).to include(:id, :content_id, :source, :domain, :reality_status,
                           :confidence, :confidence_label, :verified, :external,
                           :internal, :confused, :corrections, :recorded_at)
    end
  end
end
