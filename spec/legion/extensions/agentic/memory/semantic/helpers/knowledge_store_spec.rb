# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Semantic::Helpers::KnowledgeStore do
  subject(:store) { described_class.new }

  describe '#store' do
    it 'creates a new concept' do
      concept = store.store(name: :dog, domain: :animals)
      expect(concept.name).to eq(:dog)
      expect(store.concept_count).to eq(1)
    end

    it 'updates existing concept on re-store' do
      store.store(name: :dog, domain: :animals)
      store.store(name: :dog, properties: { legs: 4 })
      expect(store.concept_count).to eq(1)
      expect(store.retrieve(name: :dog).get_property(:legs)).to eq(4)
    end
  end

  describe '#relate' do
    it 'creates relation between concepts' do
      store.relate(source: :dog, target: :mammal, type: :is_a)
      rels = store.query_relations(name: :dog, type: :is_a)
      expect(rels.size).to eq(1)
      expect(rels.first[:target]).to eq(:mammal)
    end

    it 'auto-creates concepts that do not exist' do
      store.relate(source: :sparrow, target: :bird, type: :is_a)
      expect(store.concept_count).to eq(2)
    end
  end

  describe '#retrieve' do
    it 'returns concept and increments access' do
      store.store(name: :dog, domain: :animals)
      concept = store.retrieve(name: :dog)
      expect(concept.access_count).to eq(1)
    end

    it 'returns nil for unknown concept' do
      expect(store.retrieve(name: :unknown)).to be_nil
    end

    it 'records retrieval in history' do
      store.store(name: :dog)
      store.retrieve(name: :dog)
      expect(store.retrieval_history.size).to eq(1)
    end
  end

  describe '#check_is_a' do
    it 'returns true for valid is_a relation' do
      store.relate(source: :dog, target: :mammal, type: :is_a)
      expect(store.check_is_a(:dog, :mammal)).to be true
    end

    it 'returns false for non-existent relation' do
      store.store(name: :dog)
      expect(store.check_is_a(:dog, :reptile)).to be false
    end
  end

  describe '#instances_of' do
    it 'finds all instances of a category' do
      store.relate(source: :dog, target: :mammal, type: :is_a)
      store.relate(source: :cat, target: :mammal, type: :is_a)
      store.relate(source: :sparrow, target: :bird, type: :is_a)
      instances = store.instances_of(:mammal)
      expect(instances.map(&:name)).to contain_exactly(:dog, :cat)
    end
  end

  describe '#spreading_activation' do
    it 'activates seed concept' do
      store.store(name: :dog)
      activated = store.spreading_activation(seed: :dog)
      expect(activated).to have_key(:dog)
    end

    it 'spreads to related concepts' do
      store.relate(source: :dog, target: :mammal, type: :is_a)
      store.relate(source: :mammal, target: :animal, type: :is_a)
      activated = store.spreading_activation(seed: :dog, hops: 3)
      expect(activated.keys).to include(:dog, :mammal)
    end

    it 'diminishes activation with each hop' do
      store.relate(source: :dog, target: :mammal, type: :is_a)
      activated = store.spreading_activation(seed: :dog)
      expect(activated[:dog]).to be > activated[:mammal] if activated.key?(:mammal)
    end
  end

  describe '#concepts_in_domain' do
    it 'returns concepts in specified domain' do
      store.store(name: :dog, domain: :animals)
      store.store(name: :ruby, domain: :programming)
      expect(store.concepts_in_domain(:animals).map(&:name)).to eq([:dog])
    end
  end

  describe '#search' do
    it 'finds concepts matching query' do
      store.store(name: :golden_retriever)
      store.store(name: :golden_gate)
      store.store(name: :poodle)
      results = store.search(:golden)
      expect(results.size).to eq(2)
    end
  end

  describe '#decay_all' do
    it 'decays all concepts' do
      store.store(name: :dog, confidence: 0.5)
      store.decay_all
      concept = store.concepts[:dog]
      expect(concept.confidence).to be < 0.5 if concept
    end

    it 'prunes faded concepts' do
      floor = Legion::Extensions::Agentic::Memory::Semantic::Helpers::Constants::CONFIDENCE_FLOOR
      store.store(name: :weak, confidence: floor + 0.004)
      store.decay_all
      expect(store.concept_count).to eq(0)
    end
  end

  describe '#to_h' do
    it 'returns stats' do
      store.store(name: :dog, domain: :animals)
      store.relate(source: :dog, target: :mammal, type: :is_a)
      h = store.to_h
      expect(h).to include(:concepts, :relations, :domains, :history_size)
      expect(h[:concepts]).to eq(2)
      expect(h[:relations]).to eq(1)
    end
  end
end
