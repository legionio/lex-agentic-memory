# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Episodic::Helpers::Constants do
  describe 'capacity constants' do
    it 'defines MAX_EPISODES as 30' do
      expect(described_class::MAX_EPISODES).to eq(30)
    end

    it 'defines MAX_BINDINGS_PER_EPISODE as 10' do
      expect(described_class::MAX_BINDINGS_PER_EPISODE).to eq(10)
    end

    it 'defines MAX_HISTORY as 200' do
      expect(described_class::MAX_HISTORY).to eq(200)
    end
  end

  describe 'timing constants' do
    it 'defines EPISODE_TTL as 120' do
      expect(described_class::EPISODE_TTL).to eq(120)
    end

    it 'defines RECENTLY_ACCESSED_WINDOW as 30' do
      expect(described_class::RECENTLY_ACCESSED_WINDOW).to eq(30)
    end
  end

  describe 'strength constants' do
    it 'defines BINDING_STRENGTH_FLOOR as 0.05' do
      expect(described_class::BINDING_STRENGTH_FLOOR).to eq(0.05)
    end

    it 'defines BINDING_DECAY as 0.015' do
      expect(described_class::BINDING_DECAY).to eq(0.015)
    end

    it 'defines DEFAULT_BINDING_STRENGTH as 0.5' do
      expect(described_class::DEFAULT_BINDING_STRENGTH).to eq(0.5)
    end

    it 'defines ATTENTION_BOOST as 0.2' do
      expect(described_class::ATTENTION_BOOST).to eq(0.2)
    end

    it 'defines REHEARSAL_BOOST as 0.15' do
      expect(described_class::REHEARSAL_BOOST).to eq(0.15)
    end

    it 'defines INTEGRATION_THRESHOLD as 0.4' do
      expect(described_class::INTEGRATION_THRESHOLD).to eq(0.4)
    end
  end

  describe 'MODALITIES' do
    it 'includes all 7 expected modalities' do
      expected = %i[verbal visual spatial semantic emotional procedural temporal]
      expect(described_class::MODALITIES).to eq(expected)
    end

    it 'is frozen' do
      expect(described_class::MODALITIES).to be_frozen
    end
  end

  describe 'COHERENCE_LABELS' do
    it 'maps low scores to :fragmented' do
      label = described_class::COHERENCE_LABELS.find { |range, _| range.cover?(0.1) }&.last
      expect(label).to eq(:fragmented)
    end

    it 'maps mid scores to :partial' do
      label = described_class::COHERENCE_LABELS.find { |range, _| range.cover?(0.45) }&.last
      expect(label).to eq(:partial)
    end

    it 'maps high scores to :coherent' do
      label = described_class::COHERENCE_LABELS.find { |range, _| range.cover?(0.7) }&.last
      expect(label).to eq(:coherent)
    end

    it 'maps very high scores to :vivid' do
      label = described_class::COHERENCE_LABELS.find { |range, _| range.cover?(0.9) }&.last
      expect(label).to eq(:vivid)
    end
  end
end
