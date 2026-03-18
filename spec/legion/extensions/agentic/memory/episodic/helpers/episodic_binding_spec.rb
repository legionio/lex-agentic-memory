# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Episodic::Helpers::EpisodicBinding do
  let(:binding) { described_class.new(modality: :verbal, content: 'hello world', source: :phonological_loop) }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(binding.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns modality as symbol' do
      expect(binding.modality).to eq(:verbal)
    end

    it 'assigns content' do
      expect(binding.content).to eq('hello world')
    end

    it 'assigns source as symbol' do
      expect(binding.source).to eq(:phonological_loop)
    end

    it 'defaults strength to DEFAULT_BINDING_STRENGTH' do
      expect(binding.strength).to eq(0.5)
    end

    it 'accepts custom strength' do
      b = described_class.new(modality: :visual, content: 'image', source: :visuospatial, strength: 0.8)
      expect(b.strength).to eq(0.8)
    end

    it 'clamps strength to 0..1' do
      b = described_class.new(modality: :visual, content: 'x', source: :perception, strength: 1.5)
      expect(b.strength).to eq(1.0)
    end

    it 'raises ArgumentError for invalid modality' do
      expect do
        described_class.new(modality: :invalid_mod, content: 'x', source: :test)
      end.to raise_error(ArgumentError, /invalid modality/)
    end

    it 'accepts all valid modalities' do
      %i[verbal visual spatial semantic emotional procedural temporal].each do |mod|
        expect { described_class.new(modality: mod, content: 'x', source: :test) }.not_to raise_error
      end
    end
  end

  describe '#decay' do
    it 'reduces strength by BINDING_DECAY' do
      initial = binding.strength
      binding.decay
      expect(binding.strength).to be_within(0.001).of(initial - 0.015)
    end

    it 'does not go below 0.0' do
      b = described_class.new(modality: :verbal, content: 'x', source: :test, strength: 0.01)
      b.decay
      expect(b.strength).to be >= 0.0
    end
  end

  describe '#strengthen' do
    it 'increases strength by the given amount' do
      initial = binding.strength
      binding.strengthen(0.1)
      expect(binding.strength).to be_within(0.001).of(initial + 0.1)
    end

    it 'clamps at 1.0' do
      b = described_class.new(modality: :verbal, content: 'x', source: :test, strength: 0.95)
      b.strengthen(0.5)
      expect(b.strength).to eq(1.0)
    end
  end

  describe '#integrated?' do
    it 'returns true when strength >= INTEGRATION_THRESHOLD' do
      b = described_class.new(modality: :verbal, content: 'x', source: :test, strength: 0.5)
      expect(b.integrated?).to be true
    end

    it 'returns false when strength < INTEGRATION_THRESHOLD' do
      b = described_class.new(modality: :verbal, content: 'x', source: :test, strength: 0.3)
      expect(b.integrated?).to be false
    end
  end

  describe '#faded?' do
    it 'returns true when strength <= BINDING_STRENGTH_FLOOR' do
      b = described_class.new(modality: :verbal, content: 'x', source: :test, strength: 0.04)
      expect(b.faded?).to be true
    end

    it 'returns false when strength is above floor' do
      expect(binding.faded?).to be false
    end
  end

  describe '#to_h' do
    it 'returns a hash with all fields' do
      h = binding.to_h
      expect(h).to include(:id, :modality, :content, :source, :strength)
    end

    it 'contains correct values' do
      h = binding.to_h
      expect(h[:modality]).to eq(:verbal)
      expect(h[:content]).to eq('hello world')
      expect(h[:source]).to eq(:phonological_loop)
    end
  end
end
