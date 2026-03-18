# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::SemanticSatiation::Helpers::Constants do
  subject(:constants) { described_class }

  describe 'numeric constants' do
    it 'defines MAX_CONCEPTS as 300' do
      expect(constants::MAX_CONCEPTS).to eq(300)
    end

    it 'defines SATIATION_RATE as 0.08' do
      expect(constants::SATIATION_RATE).to eq(0.08)
    end

    it 'defines RECOVERY_RATE as 0.03' do
      expect(constants::RECOVERY_RATE).to eq(0.03)
    end

    it 'defines SATIATION_THRESHOLD as 0.7' do
      expect(constants::SATIATION_THRESHOLD).to eq(0.7)
    end

    it 'defines DEFAULT_FLUENCY as 1.0' do
      expect(constants::DEFAULT_FLUENCY).to eq(1.0)
    end
  end

  describe 'FLUENCY_LABELS' do
    it 'maps high fluency to :fluent' do
      label = constants::FLUENCY_LABELS.find { |range, _| range.cover?(0.9) }&.last
      expect(label).to eq(:fluent)
    end

    it 'maps mid-high fluency to :normal' do
      label = constants::FLUENCY_LABELS.find { |range, _| range.cover?(0.7) }&.last
      expect(label).to eq(:normal)
    end

    it 'maps mid fluency to :reduced' do
      label = constants::FLUENCY_LABELS.find { |range, _| range.cover?(0.5) }&.last
      expect(label).to eq(:reduced)
    end

    it 'maps low fluency to :satiated' do
      label = constants::FLUENCY_LABELS.find { |range, _| range.cover?(0.3) }&.last
      expect(label).to eq(:satiated)
    end

    it 'maps very low fluency to :meaningless' do
      label = constants::FLUENCY_LABELS.find { |range, _| range.cover?(0.1) }&.last
      expect(label).to eq(:meaningless)
    end
  end

  describe 'NOVELTY_LABELS' do
    it 'maps high novelty to :novel' do
      label = constants::NOVELTY_LABELS.find { |range, _| range.cover?(0.9) }&.last
      expect(label).to eq(:novel)
    end

    it 'maps mid-high novelty to :familiar' do
      label = constants::NOVELTY_LABELS.find { |range, _| range.cover?(0.7) }&.last
      expect(label).to eq(:familiar)
    end

    it 'maps mid novelty to :routine' do
      label = constants::NOVELTY_LABELS.find { |range, _| range.cover?(0.5) }&.last
      expect(label).to eq(:routine)
    end

    it 'maps low novelty to :overexposed' do
      label = constants::NOVELTY_LABELS.find { |range, _| range.cover?(0.3) }&.last
      expect(label).to eq(:overexposed)
    end

    it 'maps very low novelty to :saturated' do
      label = constants::NOVELTY_LABELS.find { |range, _| range.cover?(0.1) }&.last
      expect(label).to eq(:saturated)
    end
  end
end
