# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::SemanticSatiation::Helpers::SatiationEngine do
  subject(:engine) { described_class.new }

  describe '#register_concept' do
    it 'registers a new concept and returns it' do
      concept = engine.register_concept(label: 'apple')
      expect(concept).to be_a(Legion::Extensions::Agentic::Memory::SemanticSatiation::Helpers::Concept)
      expect(concept.label).to eq('apple')
    end

    it 'returns existing concept if label already registered' do
      c1 = engine.register_concept(label: 'apple')
      c2 = engine.register_concept(label: 'apple')
      expect(c1.id).to eq(c2.id)
    end

    it 'assigns the given domain' do
      concept = engine.register_concept(label: 'oak', domain: :nature)
      expect(concept.domain).to eq(:nature)
    end

    it 'defaults domain to :general' do
      concept = engine.register_concept(label: 'test')
      expect(concept.domain).to eq(:general)
    end

    it 'stores concept in @concepts' do
      concept = engine.register_concept(label: 'pear')
      expect(engine.concepts[concept.id]).to eq(concept)
    end
  end

  describe '#expose_concept' do
    it 'reduces fluency for a registered concept' do
      concept = engine.register_concept(label: 'word')
      engine.expose_concept(concept_id: concept.id)
      expect(concept.fluency).to be < 1.0
    end

    it 'returns error hash for unknown concept_id' do
      result = engine.expose_concept(concept_id: 'nonexistent')
      expect(result[:error]).to eq(:not_found)
    end

    it 'returns concept hash on success' do
      concept = engine.register_concept(label: 'tree')
      result = engine.expose_concept(concept_id: concept.id)
      expect(result[:fluency]).to be_a(Float)
    end
  end

  describe '#expose_by_label' do
    it 'creates and exposes a concept by label' do
      result = engine.expose_by_label(label: 'cloud')
      expect(result[:fluency]).to be < 1.0
    end

    it 'reuses existing concept on second exposure' do
      engine.expose_by_label(label: 'cloud')
      engine.expose_by_label(label: 'cloud')
      concepts_with_label = engine.concepts.values.select { |c| c.label == 'cloud' }
      expect(concepts_with_label.size).to eq(1)
    end

    it 'increments exposure_count each call' do
      2.times { engine.expose_by_label(label: 'rain') }
      concept = engine.concepts.values.find { |c| c.label == 'rain' }
      expect(concept.exposure_count).to eq(2)
    end
  end

  describe '#recover_all' do
    it 'recovers all concepts' do
      engine.expose_by_label(label: 'a')
      engine.expose_by_label(label: 'b')
      result = engine.recover_all
      expect(result[:recovered]).to eq(2)
    end

    it 'increases fluency of exposed concepts' do
      engine.expose_by_label(label: 'test')
      concept = engine.concepts.values.first
      fluency_before = concept.fluency
      engine.recover_all
      expect(concept.fluency).to be > fluency_before
    end
  end

  describe '#satiated_concepts' do
    it 'returns empty array when no concepts are satiated' do
      engine.register_concept(label: 'fresh')
      expect(engine.satiated_concepts).to be_empty
    end

    it 'returns satiated concepts' do
      engine.register_concept(label: 'worn')
      concept = engine.concepts.values.first
      15.times { concept.expose! }
      expect(engine.satiated_concepts).to include(concept)
    end
  end

  describe '#most_exposed' do
    it 'returns concepts sorted by exposure_count descending' do
      engine.expose_by_label(label: 'a')
      3.times { engine.expose_by_label(label: 'b') }
      2.times { engine.expose_by_label(label: 'c') }
      result = engine.most_exposed(limit: 3)
      expect(result.first.label).to eq('b')
    end

    it 'respects limit parameter' do
      5.times { |i| engine.expose_by_label(label: "word#{i}") }
      expect(engine.most_exposed(limit: 3).size).to eq(3)
    end
  end

  describe '#freshest' do
    it 'returns concepts sorted by fluency descending' do
      engine.register_concept(label: 'fresh')
      worn = engine.register_concept(label: 'worn')
      5.times { worn.expose! }
      result = engine.freshest(limit: 2)
      expect(result.first.label).to eq('fresh')
    end

    it 'respects limit parameter' do
      5.times { |i| engine.register_concept(label: "c#{i}") }
      expect(engine.freshest(limit: 2).size).to eq(2)
    end
  end

  describe '#domain_satiation' do
    it 'returns average fluency for domain' do
      engine.expose_by_label(label: 'sun', domain: :nature)
      engine.expose_by_label(label: 'moon', domain: :nature)
      result = engine.domain_satiation(domain: :nature)
      expect(result).to be < 1.0
      expect(result).to be > 0.0
    end

    it 'returns 0.0 for unknown domain' do
      expect(engine.domain_satiation(domain: :unknown)).to eq(0.0)
    end
  end

  describe '#novelty_report' do
    it 'returns a hash distribution' do
      engine.register_concept(label: 'new')
      report = engine.novelty_report
      expect(report).to be_a(Hash)
    end

    it 'counts concepts per novelty label' do
      engine.register_concept(label: 'fresh')
      report = engine.novelty_report
      expect(report[:novel]).to eq(1)
    end
  end

  describe '#prune_saturated' do
    it 'removes concepts with fluency <= 0.05' do
      concept = engine.register_concept(label: 'stale')
      allow(concept).to receive(:fluency).and_return(0.03)
      removed = engine.prune_saturated
      expect(removed).to eq(1)
    end

    it 'does not remove healthy concepts' do
      engine.register_concept(label: 'healthy')
      engine.prune_saturated
      expect(engine.concepts.size).to eq(1)
    end
  end

  describe '#to_h' do
    it 'includes expected keys' do
      h = engine.to_h
      expect(h.keys).to include(:concept_count, :satiated_count, :novelty_report, :most_exposed, :freshest)
    end

    it 'reflects current state' do
      engine.register_concept(label: 'test')
      expect(engine.to_h[:concept_count]).to eq(1)
    end
  end
end
