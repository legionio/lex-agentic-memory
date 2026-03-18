# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Nostalgia::Helpers::NostalgicMemory do
  subject(:memory) { described_class.new(content: 'summer camp', domain: :place, original_valence: 0.6) }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(memory.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores content' do
      expect(memory.content).to eq('summer camp')
    end

    it 'normalizes domain' do
      expect(memory.domain).to eq(:place)
    end

    it 'defaults temporal_distance to 0' do
      expect(memory.temporal_distance).to eq(0)
    end

    it 'clamps unknown domain to :unknown' do
      m = described_class.new(content: 'test', domain: :bogus)
      expect(m.domain).to eq(:unknown)
    end

    it 'clamps warmth to WARMTH_CEILING' do
      m = described_class.new(content: 'test', warmth: 1.5)
      expect(m.warmth).to be <= Legion::Extensions::Agentic::Memory::Nostalgia::Helpers::Constants::WARMTH_CEILING
    end
  end

  describe '#age!' do
    it 'increments temporal_distance' do
      memory.age!
      expect(memory.temporal_distance).to eq(1)
    end

    it 'increases warmth' do
      original = memory.warmth
      memory.age!
      expect(memory.warmth).to be > original
    end

    it 'returns self for chaining' do
      expect(memory.age!).to eq(memory)
    end

    it 'does not exceed WARMTH_CEILING after many ages' do
      100.times { memory.age! }
      expect(memory.warmth).to be <= Legion::Extensions::Agentic::Memory::Nostalgia::Helpers::Constants::WARMTH_CEILING
    end
  end

  describe '#warm!' do
    it 'increases warmth' do
      original = memory.warmth
      memory.warm!(0.1)
      expect(memory.warmth).to be > original
    end

    it 'returns self for chaining' do
      expect(memory.warm!).to eq(memory)
    end

    it 'does not exceed WARMTH_CEILING' do
      50.times { memory.warm!(0.5) }
      expect(memory.warmth).to be <= Legion::Extensions::Agentic::Memory::Nostalgia::Helpers::Constants::WARMTH_CEILING
    end
  end

  describe '#cool!' do
    it 'decreases warmth' do
      memory.warm!(0.3)
      before = memory.warmth
      memory.cool!(0.1)
      expect(memory.warmth).to be < before
    end

    it 'does not go below 0' do
      m = described_class.new(content: 'test', warmth: 0.0)
      m.cool!(1.0)
      expect(m.warmth).to eq(0.0)
    end

    it 'returns self for chaining' do
      expect(memory.cool!).to eq(memory)
    end
  end

  describe '#rosy?' do
    it 'returns false when warmth equals original_valence' do
      m = described_class.new(content: 'test', warmth: 0.5, original_valence: 0.5)
      expect(m.rosy?).to be false
    end

    it 'returns true when warmth exceeds original_valence' do
      m = described_class.new(content: 'test', warmth: 0.8, original_valence: 0.3)
      expect(m.rosy?).to be true
    end
  end

  describe '#bittersweet?' do
    it 'returns true for high warmth but low original valence' do
      m = described_class.new(content: 'test', warmth: 0.7, original_valence: 0.2)
      expect(m.bittersweet?).to be true
    end

    it 'returns false for high warmth and high original valence' do
      m = described_class.new(content: 'test', warmth: 0.8, original_valence: 0.8)
      expect(m.bittersweet?).to be false
    end

    it 'returns false for low warmth' do
      m = described_class.new(content: 'test', warmth: 0.2, original_valence: 0.1)
      expect(m.bittersweet?).to be false
    end
  end

  describe '#warmth_label' do
    it 'returns a symbol' do
      expect(memory.warmth_label).to be_a(Symbol)
    end
  end

  describe '#to_h' do
    it 'includes all key fields' do
      h = memory.to_h
      expect(h).to include(:id, :content, :domain, :warmth, :warmth_label, :temporal_distance,
                           :original_valence, :current_valence, :rosy, :bittersweet, :created_at)
    end
  end
end
