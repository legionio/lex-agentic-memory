# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Semantic::Helpers::Concept do
  subject(:concept) { described_class.new(name: :dog, domain: :animals) }

  describe '#initialize' do
    it 'assigns fields' do
      expect(concept.name).to eq(:dog)
      expect(concept.domain).to eq(:animals)
      expect(concept.access_count).to eq(0)
    end

    it 'defaults confidence to DEFAULT_CONFIDENCE' do
      expect(concept.confidence).to eq(Legion::Extensions::Agentic::Memory::Semantic::Helpers::Constants::DEFAULT_CONFIDENCE)
    end

    it 'assigns uuid and timestamp' do
      expect(concept.id).to match(/\A[0-9a-f-]{36}\z/)
      expect(concept.created_at).to be_a(Time)
    end

    it 'accepts custom properties' do
      c = described_class.new(name: :cat, properties: { legs: 4 })
      expect(c.get_property(:legs)).to eq(4)
    end
  end

  describe '#add_relation' do
    it 'adds a typed relation' do
      rel = concept.add_relation(type: :is_a, target_name: :mammal)
      expect(rel[:type]).to eq(:is_a)
      expect(rel[:target]).to eq(:mammal)
      expect(concept.relations.size).to eq(1)
    end

    it 'rejects invalid relation types' do
      expect(concept.add_relation(type: :invalid, target_name: :thing)).to be false
    end

    it 'reinforces existing relation instead of duplicating' do
      concept.add_relation(type: :is_a, target_name: :mammal)
      concept.add_relation(type: :is_a, target_name: :mammal)
      expect(concept.relations.size).to eq(1)
    end
  end

  describe '#relations_of_type' do
    it 'filters by type' do
      concept.add_relation(type: :is_a, target_name: :mammal)
      concept.add_relation(type: :has_a, target_name: :tail)
      expect(concept.relations_of_type(:is_a).size).to eq(1)
    end
  end

  describe '#related_concepts' do
    it 'lists unique related concept names' do
      concept.add_relation(type: :is_a, target_name: :mammal)
      concept.add_relation(type: :has_a, target_name: :tail)
      expect(concept.related_concepts).to contain_exactly(:mammal, :tail)
    end
  end

  describe '#access' do
    it 'increments count and boosts confidence' do
      before = concept.confidence
      concept.access
      expect(concept.access_count).to eq(1)
      expect(concept.confidence).to be > before
    end
  end

  describe '#decay' do
    it 'reduces confidence' do
      before = concept.confidence
      concept.decay
      expect(concept.confidence).to be < before
    end

    it 'does not drop below floor' do
      100.times { concept.decay }
      expect(concept.confidence).to be >= Legion::Extensions::Agentic::Memory::Semantic::Helpers::Constants::CONFIDENCE_FLOOR
    end

    it 'prunes weak relations' do
      concept.add_relation(type: :is_a, target_name: :mammal, confidence: 0.06)
      100.times { concept.decay }
      expect(concept.relations).to be_empty
    end
  end

  describe '#faded?' do
    it 'returns false for healthy concept' do
      expect(concept.faded?).to be false
    end

    it 'returns true at floor' do
      concept.confidence = Legion::Extensions::Agentic::Memory::Semantic::Helpers::Constants::CONFIDENCE_FLOOR
      expect(concept.faded?).to be true
    end
  end

  describe '#label' do
    it 'returns :provisional for default confidence' do
      expect(concept.label).to eq(:provisional)
    end

    it 'returns :established for high confidence' do
      concept.confidence = 0.9
      expect(concept.label).to eq(:established)
    end
  end

  describe '#to_h' do
    it 'returns hash with all fields' do
      h = concept.to_h
      expect(h).to include(:id, :name, :domain, :confidence, :properties, :relations, :access_count, :label)
    end
  end
end
