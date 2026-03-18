# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Semantic::Runners::SemanticMemory do
  let(:client) { Legion::Extensions::Agentic::Memory::Semantic::Client.new }

  describe '#store_concept' do
    it 'stores a concept' do
      result = client.store_concept(name: :dog, domain: :animals)
      expect(result[:success]).to be true
      expect(result[:concept][:name]).to eq(:dog)
    end
  end

  describe '#relate_concepts' do
    it 'creates a relation' do
      result = client.relate_concepts(source: :dog, target: :mammal, type: :is_a)
      expect(result[:success]).to be true
      expect(result[:type]).to eq(:is_a)
    end
  end

  describe '#retrieve_concept' do
    it 'retrieves stored concept' do
      client.store_concept(name: :dog, domain: :animals)
      result = client.retrieve_concept(name: :dog)
      expect(result[:found]).to be true
      expect(result[:concept][:name]).to eq(:dog)
    end

    it 'returns found: false for unknown' do
      result = client.retrieve_concept(name: :unknown)
      expect(result[:found]).to be false
    end
  end

  describe '#query_concept_relations' do
    it 'returns relations' do
      client.relate_concepts(source: :dog, target: :mammal, type: :is_a)
      result = client.query_concept_relations(name: :dog, type: :is_a)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#check_category' do
    it 'checks is_a membership' do
      client.relate_concepts(source: :dog, target: :mammal, type: :is_a)
      result = client.check_category(concept: :dog, category: :mammal)
      expect(result[:is_member]).to be true
    end

    it 'returns false for non-member' do
      client.store_concept(name: :dog)
      result = client.check_category(concept: :dog, category: :reptile)
      expect(result[:is_member]).to be false
    end
  end

  describe '#find_instances' do
    it 'finds instances of category' do
      client.relate_concepts(source: :dog, target: :mammal, type: :is_a)
      client.relate_concepts(source: :cat, target: :mammal, type: :is_a)
      result = client.find_instances(category: :mammal)
      expect(result[:count]).to eq(2)
    end
  end

  describe '#activate_spread' do
    it 'spreads activation from seed' do
      client.relate_concepts(source: :dog, target: :mammal, type: :is_a)
      result = client.activate_spread(seed: :dog)
      expect(result[:success]).to be true
      expect(result[:activated]).to have_key(:dog)
    end
  end

  describe '#concepts_in' do
    it 'returns concepts in domain' do
      client.store_concept(name: :dog, domain: :animals)
      client.store_concept(name: :ruby, domain: :programming)
      result = client.concepts_in(domain: :animals)
      expect(result[:count]).to eq(1)
      expect(result[:concepts]).to eq([:dog])
    end
  end

  describe '#update_semantic_memory' do
    it 'decays and returns counts' do
      client.store_concept(name: :dog)
      result = client.update_semantic_memory
      expect(result[:success]).to be true
      expect(result).to have_key(:concepts)
      expect(result).to have_key(:relations)
    end
  end

  describe '#semantic_memory_stats' do
    it 'returns stats' do
      result = client.semantic_memory_stats
      expect(result[:success]).to be true
      expect(result[:stats]).to include(:concepts, :relations, :domains)
    end
  end
end
