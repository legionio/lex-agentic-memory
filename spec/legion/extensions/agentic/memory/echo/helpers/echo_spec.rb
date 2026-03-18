# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Echo::Helpers::Echo do
  subject(:echo) { described_class.new(content: 'previous thought about security') }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(echo.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores content' do
      expect(echo.content).to eq('previous thought about security')
    end

    it 'defaults echo_type to :thought' do
      expect(echo.echo_type).to eq(:thought)
    end

    it 'defaults domain to :general' do
      expect(echo.domain).to eq(:general)
    end

    it 'defaults intensity to 0.8' do
      expect(echo.intensity).to eq(0.8)
    end

    it 'preserves original_intensity' do
      expect(echo.original_intensity).to eq(0.8)
    end

    it 'clamps intensity' do
      high = described_class.new(content: 'x', intensity: 5.0)
      expect(high.intensity).to eq(1.0)
    end

    it 'validates echo_type' do
      bad = described_class.new(content: 'x', echo_type: :nonexistent)
      expect(bad.echo_type).to eq(:thought)
    end
  end

  describe '#decay!' do
    it 'reduces intensity' do
      original = echo.intensity
      echo.decay!
      expect(echo.intensity).to be < original
    end

    it 'increments decay_count' do
      echo.decay!
      expect(echo.decay_count).to eq(1)
    end

    it 'clamps at 0.0' do
      15.times { echo.decay! }
      expect(echo.intensity).to eq(0.0)
    end
  end

  describe '#reinforce!' do
    it 'increases intensity' do
      echo.decay!
      original = echo.intensity
      echo.reinforce!
      expect(echo.intensity).to be > original
    end

    it 'clamps at 1.0' do
      5.times { echo.reinforce! }
      expect(echo.intensity).to eq(1.0)
    end
  end

  describe '#silent?' do
    it 'is false when active' do
      expect(echo.silent?).to be false
    end

    it 'is true when fully decayed' do
      10.times { echo.decay! }
      expect(echo.silent?).to be true
    end
  end

  describe '#priming?' do
    it 'is true at default intensity' do
      expect(echo.priming?).to be true
    end

    it 'is false when very faint' do
      faint = described_class.new(content: 'x', intensity: 0.1)
      expect(faint.priming?).to be false
    end
  end

  describe '#interfering?' do
    it 'is true at default intensity' do
      expect(echo.interfering?).to be true
    end

    it 'is false when below threshold' do
      weak = described_class.new(content: 'x', intensity: 0.2)
      expect(weak.interfering?).to be false
    end
  end

  describe '#persistence' do
    it 'is 1.0 when not decayed' do
      expect(echo.persistence).to eq(1.0)
    end

    it 'decreases after decay' do
      echo.decay!
      expect(echo.persistence).to be < 1.0
    end
  end

  describe '#to_h' do
    it 'includes all fields' do
      hash = echo.to_h
      expect(hash).to include(
        :id, :content, :echo_type, :domain, :intensity, :original_intensity,
        :intensity_label, :effect_label, :priming, :interfering, :silent,
        :persistence, :decay_count, :created_at
      )
    end
  end
end
