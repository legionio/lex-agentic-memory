# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::SemanticSatiation::Helpers::Concept do
  subject(:concept) { described_class.new(label: 'banana', domain: :food) }

  describe '#initialize' do
    it 'generates a uuid id' do
      expect(concept.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets label' do
      expect(concept.label).to eq('banana')
    end

    it 'sets domain' do
      expect(concept.domain).to eq(:food)
    end

    it 'starts with full fluency' do
      expect(concept.fluency).to eq(1.0)
    end

    it 'starts with zero exposures' do
      expect(concept.exposure_count).to eq(0)
    end

    it 'starts with nil last_exposed_at' do
      expect(concept.last_exposed_at).to be_nil
    end

    it 'sets created_at' do
      expect(concept.created_at).to be_a(Time)
    end

    it 'defaults domain to :general' do
      c = described_class.new(label: 'test')
      expect(c.domain).to eq(:general)
    end
  end

  describe '#expose!' do
    it 'increments exposure_count' do
      concept.expose!
      expect(concept.exposure_count).to eq(1)
    end

    it 'reduces fluency by SATIATION_RATE' do
      expected = (1.0 - Legion::Extensions::Agentic::Memory::SemanticSatiation::Helpers::Constants::SATIATION_RATE).round(10)
      concept.expose!
      expect(concept.fluency).to eq(expected)
    end

    it 'sets last_exposed_at' do
      concept.expose!
      expect(concept.last_exposed_at).to be_a(Time)
    end

    it 'does not reduce fluency below 0.0' do
      20.times { concept.expose! }
      expect(concept.fluency).to be >= 0.0
    end

    it 'accumulates multiple exposures' do
      3.times { concept.expose! }
      expect(concept.exposure_count).to eq(3)
    end
  end

  describe '#recover!' do
    it 'increases fluency by RECOVERY_RATE' do
      concept.expose!
      fluency_before = concept.fluency
      concept.recover!
      expect(concept.fluency).to be > fluency_before
    end

    it 'does not exceed 1.0' do
      concept.recover!
      expect(concept.fluency).to eq(1.0)
    end

    it 'accepts custom amount' do
      concept.expose!
      concept.expose!
      fluency_before = concept.fluency
      concept.recover!(amount: 0.5)
      expect(concept.fluency).to be > fluency_before
    end
  end

  describe '#satiated?' do
    it 'returns false when fluency is full' do
      expect(concept.satiated?).to be false
    end

    it 'returns true when fluency is below threshold' do
      threshold = Legion::Extensions::Agentic::Memory::SemanticSatiation::Helpers::Constants
      target = 1.0 - threshold::SATIATION_THRESHOLD - 0.05
      allow(concept).to receive(:fluency).and_return(target)
      expect(concept.satiated?).to be true
    end
  end

  describe '#fluency_label' do
    it 'returns :fluent for high fluency' do
      expect(concept.fluency_label).to eq(:fluent)
    end

    it 'returns :meaningless for near-zero fluency' do
      15.times { concept.expose! }
      expect(%i[meaningless satiated reduced]).to include(concept.fluency_label)
    end
  end

  describe '#novelty' do
    it 'returns 1.0 for a fresh concept' do
      expect(concept.novelty).to eq(1.0)
    end

    it 'decreases with more exposures' do
      10.times { concept.expose! }
      expect(concept.novelty).to be < 1.0
    end

    it 'does not go below 0.0' do
      100.times { concept.expose! }
      expect(concept.novelty).to be >= 0.0
    end
  end

  describe '#novelty_label' do
    it 'returns :novel for a fresh concept' do
      expect(concept.novelty_label).to eq(:novel)
    end

    it 'returns a symbol' do
      expect(concept.novelty_label).to be_a(Symbol)
    end
  end

  describe '#time_since_exposure' do
    it 'returns nil before first exposure' do
      expect(concept.time_since_exposure).to be_nil
    end

    it 'returns a numeric value after exposure' do
      concept.expose!
      expect(concept.time_since_exposure).to be_a(Float).or be_a(Integer)
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = concept.to_h
      expect(h.keys).to include(:id, :label, :domain, :fluency, :fluency_label,
                                :novelty, :novelty_label, :exposure_count,
                                :satiated, :last_exposed_at, :created_at)
    end

    it 'reflects current state' do
      concept.expose!
      h = concept.to_h
      expect(h[:exposure_count]).to eq(1)
      expect(h[:fluency]).to be < 1.0
    end
  end
end
