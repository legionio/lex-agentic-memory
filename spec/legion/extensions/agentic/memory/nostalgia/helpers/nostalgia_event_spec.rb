# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Nostalgia::Helpers::NostalgiaEvent do
  subject(:event) do
    described_class.new(
      memory_id:      'abc-123',
      trigger:        'old song',
      intensity:      0.7,
      effect_on_mood: 0.4
    )
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(event.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores memory_id' do
      expect(event.memory_id).to eq('abc-123')
    end

    it 'stores trigger' do
      expect(event.trigger).to eq('old song')
    end

    it 'clamps intensity to [0, 1]' do
      e = described_class.new(memory_id: 'x', trigger: 't', intensity: 1.8)
      expect(e.intensity).to eq(1.0)
    end

    it 'clamps effect_on_mood to [-1, 1]' do
      e = described_class.new(memory_id: 'x', trigger: 't', intensity: 0.5, effect_on_mood: 2.0)
      expect(e.effect_on_mood).to eq(1.0)
    end

    it 'defaults effect_on_mood to 0.0' do
      e = described_class.new(memory_id: 'x', trigger: 't', intensity: 0.5)
      expect(e.effect_on_mood).to eq(0.0)
    end
  end

  describe '#nostalgia_label' do
    it 'returns a symbol' do
      expect(event.nostalgia_label).to be_a(Symbol)
    end

    it 'returns :vivid for intensity 0.7' do
      expect(event.nostalgia_label).to eq(:vivid)
    end
  end

  describe '#to_h' do
    it 'includes all fields' do
      h = event.to_h
      expect(h).to include(:id, :memory_id, :trigger, :intensity, :nostalgia_label,
                           :effect_on_mood, :occurred_at)
    end
  end
end
