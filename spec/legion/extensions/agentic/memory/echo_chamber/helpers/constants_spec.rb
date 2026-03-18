# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::EchoChamber::Helpers::Constants do
  describe 'numeric constants' do
    it 'defines MAX_ECHOES as 500' do
      expect(described_class::MAX_ECHOES).to eq(500)
    end

    it 'defines MAX_CHAMBERS as 50' do
      expect(described_class::MAX_CHAMBERS).to eq(50)
    end

    it 'defines AMPLIFICATION_RATE as 0.1' do
      expect(described_class::AMPLIFICATION_RATE).to eq(0.1)
    end

    it 'defines DECAY_RATE as 0.02' do
      expect(described_class::DECAY_RATE).to eq(0.02)
    end

    it 'defines DISRUPTION_THRESHOLD as 0.7' do
      expect(described_class::DISRUPTION_THRESHOLD).to eq(0.7)
    end

    it 'defines SEALED_THRESHOLD as 0.8' do
      expect(described_class::SEALED_THRESHOLD).to eq(0.8)
    end

    it 'defines POROUS_THRESHOLD as 0.3' do
      expect(described_class::POROUS_THRESHOLD).to eq(0.3)
    end
  end

  describe 'ECHO_TYPES' do
    it 'contains belief' do
      expect(described_class::ECHO_TYPES).to include(:belief)
    end

    it 'contains assumption' do
      expect(described_class::ECHO_TYPES).to include(:assumption)
    end

    it 'contains bias' do
      expect(described_class::ECHO_TYPES).to include(:bias)
    end

    it 'contains hypothesis' do
      expect(described_class::ECHO_TYPES).to include(:hypothesis)
    end

    it 'contains conviction' do
      expect(described_class::ECHO_TYPES).to include(:conviction)
    end

    it 'is frozen' do
      expect(described_class::ECHO_TYPES).to be_frozen
    end
  end

  describe 'CHAMBER_STATES' do
    it 'contains all expected states' do
      expect(described_class::CHAMBER_STATES).to contain_exactly(
        :forming, :resonating, :saturated, :disrupted, :collapsed
      )
    end

    it 'is frozen' do
      expect(described_class::CHAMBER_STATES).to be_frozen
    end
  end

  describe 'RESONANCE_LABELS' do
    it 'maps high values to :thunderous' do
      expect(described_class::RESONANCE_LABELS.find { |r, _| r.cover?(0.9) }&.last).to eq(:thunderous)
    end

    it 'maps mid values to :humming' do
      expect(described_class::RESONANCE_LABELS.find { |r, _| r.cover?(0.5) }&.last).to eq(:humming)
    end

    it 'maps low values to :silent' do
      expect(described_class::RESONANCE_LABELS.find { |r, _| r.cover?(0.1) }&.last).to eq(:silent)
    end

    it 'is frozen' do
      expect(described_class::RESONANCE_LABELS).to be_frozen
    end
  end

  describe 'AMPLIFICATION_LABELS' do
    it 'maps high values to :deafening' do
      expect(described_class::AMPLIFICATION_LABELS.find { |r, _| r.cover?(0.9) }&.last).to eq(:deafening)
    end

    it 'maps mid values to :moderate' do
      expect(described_class::AMPLIFICATION_LABELS.find { |r, _| r.cover?(0.5) }&.last).to eq(:moderate)
    end

    it 'maps low values to :muted' do
      expect(described_class::AMPLIFICATION_LABELS.find { |r, _| r.cover?(0.1) }&.last).to eq(:muted)
    end
  end

  describe '.label_for' do
    it 'returns the correct label for a value in range' do
      label = described_class.label_for(described_class::RESONANCE_LABELS, 0.9)
      expect(label).to eq(:thunderous)
    end

    it 'returns label for boundary value' do
      label = described_class.label_for(described_class::RESONANCE_LABELS, 0.8)
      expect(label).to eq(:thunderous)
    end

    it 'returns :silent for very low values' do
      label = described_class.label_for(described_class::RESONANCE_LABELS, 0.1)
      expect(label).to eq(:silent)
    end

    it 'returns nil for no match' do
      label = described_class.label_for({}, 0.5)
      expect(label).to be_nil
    end

    it 'works with AMPLIFICATION_LABELS' do
      label = described_class.label_for(described_class::AMPLIFICATION_LABELS, 0.75)
      expect(label).to eq(:loud)
    end
  end
end
