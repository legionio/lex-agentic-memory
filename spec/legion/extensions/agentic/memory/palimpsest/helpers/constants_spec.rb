# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Palimpsest::Helpers::Constants do
  describe 'constants' do
    it 'defines MAX_PALIMPSESTS' do
      expect(described_class::MAX_PALIMPSESTS).to eq(200)
    end

    it 'defines MAX_LAYERS_PER_TOPIC' do
      expect(described_class::MAX_LAYERS_PER_TOPIC).to eq(20)
    end

    it 'defines DEFAULT_CONFIDENCE' do
      expect(described_class::DEFAULT_CONFIDENCE).to eq(0.7)
    end

    it 'defines GHOST_THRESHOLD' do
      expect(described_class::GHOST_THRESHOLD).to eq(0.1)
    end

    it 'defines EROSION_RATE' do
      expect(described_class::EROSION_RATE).to eq(0.05)
    end

    it 'defines GHOST_DECAY' do
      expect(described_class::GHOST_DECAY).to eq(0.02)
    end

    it 'defines 8 LAYER_DOMAINS' do
      expect(described_class::LAYER_DOMAINS.size).to eq(8)
    end

    it 'includes expected domains' do
      expect(described_class::LAYER_DOMAINS).to include(:factual, :procedural, :normative, :identity)
    end
  end

  describe '.label_for' do
    it 'returns correct CONFIDENCE_LABELS label' do
      expect(described_class.label_for(described_class::CONFIDENCE_LABELS, 0.95)).to eq(:certain)
      expect(described_class.label_for(described_class::CONFIDENCE_LABELS, 0.75)).to eq(:high)
      expect(described_class.label_for(described_class::CONFIDENCE_LABELS, 0.55)).to eq(:moderate)
      expect(described_class.label_for(described_class::CONFIDENCE_LABELS, 0.35)).to eq(:low)
      expect(described_class.label_for(described_class::CONFIDENCE_LABELS, 0.15)).to eq(:faint)
      expect(described_class.label_for(described_class::CONFIDENCE_LABELS, 0.05)).to eq(:ghost)
    end

    it 'returns correct GHOST_LABELS label' do
      expect(described_class.label_for(described_class::GHOST_LABELS, 0.6)).to eq(:strong_ghost)
      expect(described_class.label_for(described_class::GHOST_LABELS, 0.4)).to eq(:moderate_ghost)
      expect(described_class.label_for(described_class::GHOST_LABELS, 0.2)).to eq(:faint_ghost)
      expect(described_class.label_for(described_class::GHOST_LABELS, 0.05)).to eq(:dissipated)
    end

    it 'returns correct DRIFT_LABELS label' do
      expect(described_class.label_for(described_class::DRIFT_LABELS, 0.8)).to eq(:radical)
      expect(described_class.label_for(described_class::DRIFT_LABELS, 0.5)).to eq(:major)
      expect(described_class.label_for(described_class::DRIFT_LABELS, 0.3)).to eq(:moderate)
      expect(described_class.label_for(described_class::DRIFT_LABELS, 0.1)).to eq(:minor)
      expect(described_class.label_for(described_class::DRIFT_LABELS, 0.01)).to eq(:stable)
    end
  end
end
