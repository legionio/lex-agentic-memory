# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Trace::Helpers::Decay do
  describe '.compute_decay' do
    it 'returns peak_strength for zero decay rate (firmware)' do
      result = described_class.compute_decay(
        peak_strength: 1.0, base_decay_rate: 0.0, ticks_since_access: 1000
      )
      expect(result).to eq(1.0)
    end

    it 'decays sensory traces fastest' do
      sensory = described_class.compute_decay(
        peak_strength: 0.4, base_decay_rate: 0.1, ticks_since_access: 100
      )
      semantic = described_class.compute_decay(
        peak_strength: 0.5, base_decay_rate: 0.01, ticks_since_access: 100
      )
      expect(sensory).to be < semantic
    end

    it 'emotional intensity slows decay' do
      without_emotion = described_class.compute_decay(
        peak_strength: 0.6, base_decay_rate: 0.02, ticks_since_access: 50, emotional_intensity: 0.0
      )
      with_emotion = described_class.compute_decay(
        peak_strength: 0.6, base_decay_rate: 0.02, ticks_since_access: 50, emotional_intensity: 0.9
      )
      expect(with_emotion).to be > without_emotion
    end

    it 'returns zero for zero peak strength' do
      result = described_class.compute_decay(
        peak_strength: 0.0, base_decay_rate: 0.01, ticks_since_access: 10
      )
      expect(result).to eq(0.0)
    end

    it 'clamps result between 0 and 1' do
      result = described_class.compute_decay(
        peak_strength: 1.0, base_decay_rate: 0.001, ticks_since_access: 1
      )
      expect(result).to be_between(0.0, 1.0)
    end

    it 'decays more with more ticks' do
      early = described_class.compute_decay(
        peak_strength: 0.5, base_decay_rate: 0.01, ticks_since_access: 10
      )
      late = described_class.compute_decay(
        peak_strength: 0.5, base_decay_rate: 0.01, ticks_since_access: 1000
      )
      expect(late).to be < early
    end
  end

  describe '.compute_reinforcement' do
    it 'increases strength by R_AMOUNT' do
      result = described_class.compute_reinforcement(current_strength: 0.5)
      expect(result).to eq(0.6)
    end

    it 'applies imprint multiplier when active' do
      result = described_class.compute_reinforcement(current_strength: 0.5, imprint_active: true)
      expect(result).to eq(0.8)
    end

    it 'clamps at 1.0' do
      result = described_class.compute_reinforcement(current_strength: 0.95)
      expect(result).to eq(1.0)
    end

    it 'clamps imprint reinforcement at 1.0' do
      result = described_class.compute_reinforcement(current_strength: 0.8, imprint_active: true)
      expect(result).to eq(1.0)
    end
  end

  describe '.compute_retrieval_score' do
    let(:trace) do
      Legion::Extensions::Agentic::Memory::Trace::Helpers::Trace.new_trace(
        type: :semantic, content_payload: { fact: 'test' }, emotional_intensity: 0.5
      )
    end

    it 'returns positive score for valid trace' do
      score = described_class.compute_retrieval_score(trace: trace)
      expect(score).to be > 0.0
    end

    it 'returns higher score for associated traces' do
      normal = described_class.compute_retrieval_score(trace: trace, associated: false)
      associated = described_class.compute_retrieval_score(trace: trace, associated: true)
      expect(associated).to be > normal
    end

    it 'recency reduces score over time' do
      recent = described_class.compute_retrieval_score(trace: trace, query_time: Time.now.utc)
      later = described_class.compute_retrieval_score(trace: trace, query_time: Time.now.utc + 7200)
      expect(later).to be < recent
    end
  end

  describe '.compute_storage_tier' do
    let(:trace) do
      Legion::Extensions::Agentic::Memory::Trace::Helpers::Trace.new_trace(
        type: :semantic, content_payload: { fact: 'test' }
      )
    end

    it 'returns :hot for recently accessed traces' do
      tier = described_class.compute_storage_tier(trace: trace)
      expect(tier).to eq(:hot)
    end

    it 'returns :warm for traces accessed within 90 days' do
      trace[:last_reinforced] = Time.now.utc - (30 * 86_400)
      tier = described_class.compute_storage_tier(trace: trace)
      expect(tier).to eq(:warm)
    end

    it 'returns :cold for old traces' do
      trace[:last_reinforced] = Time.now.utc - (100 * 86_400)
      tier = described_class.compute_storage_tier(trace: trace)
      expect(tier).to eq(:cold)
    end

    it 'returns :erased for traces below prune threshold' do
      trace[:strength] = 0.005
      tier = described_class.compute_storage_tier(trace: trace)
      expect(tier).to eq(:erased)
    end
  end
end
