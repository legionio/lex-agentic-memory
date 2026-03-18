# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Nostalgia::Helpers::Constants do
  describe 'constants' do
    it 'defines MAX_MEMORIES' do
      expect(described_class::MAX_MEMORIES).to eq(300)
    end

    it 'defines MAX_EVENTS' do
      expect(described_class::MAX_EVENTS).to eq(500)
    end

    it 'defines DEFAULT_WARMTH' do
      expect(described_class::DEFAULT_WARMTH).to eq(0.3)
    end

    it 'defines WARMTH_GROWTH' do
      expect(described_class::WARMTH_GROWTH).to eq(0.02)
    end

    it 'defines WARMTH_CEILING' do
      expect(described_class::WARMTH_CEILING).to eq(0.95)
    end

    it 'defines WARMTH_DECAY' do
      expect(described_class::WARMTH_DECAY).to eq(0.01)
    end

    it 'defines TRIGGER_SENSITIVITY' do
      expect(described_class::TRIGGER_SENSITIVITY).to eq(0.3)
    end

    it 'defines 8 MEMORY_DOMAINS' do
      expect(described_class::MEMORY_DOMAINS.size).to eq(8)
      expect(described_class::MEMORY_DOMAINS).to include(:relationship, :place, :achievement, :unknown)
    end
  end

  describe '.label_for' do
    it 'returns warmth label for low value' do
      expect(described_class.label_for(described_class::WARMTH_LABELS, 0.1)).to eq(:faint)
    end

    it 'returns warmth label for mid value' do
      expect(described_class.label_for(described_class::WARMTH_LABELS, 0.5)).to eq(:warm)
    end

    it 'returns warmth label for high value' do
      expect(described_class.label_for(described_class::WARMTH_LABELS, 0.9)).to eq(:glowing)
    end

    it 'returns nostalgia label' do
      expect(described_class.label_for(described_class::NOSTALGIA_LABELS, 0.7)).to eq(:vivid)
    end

    it 'returns retrospection label' do
      expect(described_class.label_for(described_class::RETROSPECTION_LABELS, 0.0)).to eq(:accurate)
    end

    it 'clamps values outside [0, 1]' do
      expect(described_class.label_for(described_class::WARMTH_LABELS, 1.5)).to eq(:glowing)
      expect(described_class.label_for(described_class::WARMTH_LABELS, -0.5)).to eq(:faint)
    end
  end
end
