# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Trace::Helpers::Trace do
  describe '.new_trace' do
    it 'creates a firmware trace with correct defaults' do
      trace = described_class.new_trace(type: :firmware, content_payload: { directive_text: 'protect' })

      expect(trace[:trace_type]).to eq(:firmware)
      expect(trace[:strength]).to eq(1.0)
      expect(trace[:base_decay_rate]).to eq(0.0)
      expect(trace[:storage_tier]).to eq(:hot)
      expect(trace[:trace_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'creates an episodic trace with correct starting strength' do
      trace = described_class.new_trace(type: :episodic, content_payload: { text: 'hello' })

      expect(trace[:strength]).to eq(0.6)
      expect(trace[:base_decay_rate]).to eq(0.02)
    end

    it 'creates a sensory trace with highest decay rate' do
      trace = described_class.new_trace(type: :sensory, content_payload: { signal: 'ping' })

      expect(trace[:strength]).to eq(0.4)
      expect(trace[:base_decay_rate]).to eq(0.1)
    end

    it 'clamps emotional values to valid ranges' do
      trace = described_class.new_trace(
        type: :semantic, content_payload: { fact: 'test' },
        emotional_valence: 2.5, emotional_intensity: -0.5
      )

      expect(trace[:emotional_valence]).to eq(1.0)
      expect(trace[:emotional_intensity]).to eq(0.0)
    end

    it 'normalizes string and structured emotional values safely' do
      trace = described_class.new_trace(
        type:                :episodic,
        content_payload:     { event: 'partner ping' },
        emotional_valence:   '{:urgency=>0.6, :importance=>0.8}',
        emotional_intensity: '0.75'
      )

      expect(trace[:emotional_valence]).to eq(0.0)
      expect(trace[:emotional_intensity]).to eq(0.75)
    end

    it 'extracts scalar valence from hash payloads when an explicit valence key exists' do
      trace = described_class.new_trace(
        type:                :semantic,
        content_payload:     { fact: 'test' },
        emotional_valence:   { valence: 0.4 },
        emotional_intensity: '2.0'
      )

      expect(trace[:emotional_valence]).to eq(0.4)
      expect(trace[:emotional_intensity]).to eq(1.0)
    end

    it 'rejects invalid trace types' do
      expect do
        described_class.new_trace(type: :bogus, content_payload: {})
      end.to raise_error(ArgumentError, /invalid trace type/)
    end

    it 'rejects invalid origins' do
      expect do
        described_class.new_trace(type: :semantic, content_payload: {}, origin: :unknown)
      end.to raise_error(ArgumentError, /invalid origin/)
    end

    it 'sets domain tags as array' do
      trace = described_class.new_trace(type: :semantic, content_payload: {}, domain_tags: %w[work calendar])

      expect(trace[:domain_tags]).to eq(%w[work calendar])
    end

    it 'initializes associated_traces as empty array' do
      trace = described_class.new_trace(type: :semantic, content_payload: {})

      expect(trace[:associated_traces]).to eq([])
    end

    it 'creates all 7 trace types' do
      described_class::TRACE_TYPES.each do |type|
        trace = described_class.new_trace(type: type, content_payload: {})
        expect(trace[:trace_type]).to eq(type)
        expect(trace[:strength]).to be_between(0.0, 1.0)
      end
    end

    it 'includes unresolved defaulting to false' do
      trace = described_class.new_trace(type: :episodic, content_payload: { text: 'hello' })

      expect(trace).to have_key(:unresolved)
      expect(trace[:unresolved]).to be false
    end

    it 'includes consolidation_candidate defaulting to false' do
      trace = described_class.new_trace(type: :episodic, content_payload: { text: 'hello' })

      expect(trace).to have_key(:consolidation_candidate)
      expect(trace[:consolidation_candidate]).to be false
    end

    it 'allows unresolved to be set to true at creation' do
      trace = described_class.new_trace(type: :episodic, content_payload: { text: 'hello' }, unresolved: true)

      expect(trace[:unresolved]).to be true
    end

    it 'allows consolidation_candidate to be set to true at creation' do
      trace = described_class.new_trace(type: :semantic, content_payload: { fact: 'test' }, consolidation_candidate: true)

      expect(trace[:consolidation_candidate]).to be true
    end
  end

  describe '.valid_trace?' do
    it 'returns true for valid traces' do
      trace = described_class.new_trace(type: :semantic, content_payload: {})
      expect(described_class.valid_trace?(trace)).to be true
    end

    it 'returns false for non-hash' do
      expect(described_class.valid_trace?('not a trace')).to be false
    end

    it 'returns false for invalid type' do
      trace = described_class.new_trace(type: :semantic, content_payload: {})
      trace[:trace_type] = :invalid
      expect(described_class.valid_trace?(trace)).to be false
    end

    it 'returns false for out-of-range strength' do
      trace = described_class.new_trace(type: :semantic, content_payload: {})
      trace[:strength] = 1.5
      expect(described_class.valid_trace?(trace)).to be false
    end
  end
end
