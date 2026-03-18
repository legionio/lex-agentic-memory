# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Paleontology::Helpers::PaleontologyEngine do
  let(:engine) { described_class.new }
  let(:fossil_args) do
    { fossil_type: :strategy, domain: :cognitive, content: 'old way',
      extinction_cause: :obsolescence }
  end

  describe '#record_extinction' do
    it 'creates a fossil' do
      f = engine.record_extinction(**fossil_args)
      expect(f.fossil_type).to eq :strategy
    end

    it 'tracks fossil in all_fossils' do
      engine.record_extinction(**fossil_args)
      expect(engine.all_fossils.size).to eq 1
    end

    it 'raises on invalid type' do
      expect do
        engine.record_extinction(fossil_type: :bogus, domain: :x,
                                 content: 'x', extinction_cause: :obsolescence)
      end.to raise_error(ArgumentError)
    end
  end

  describe '#begin_excavation' do
    it 'creates an excavation' do
      exc = engine.begin_excavation(target_stratum: 1)
      expect(exc.target_stratum).to eq 1
    end

    it 'tracks in all_excavations' do
      engine.begin_excavation(target_stratum: 0)
      expect(engine.all_excavations.size).to eq 1
    end
  end

  describe '#excavate!' do
    it 'returns fossil from matching stratum' do
      engine.record_extinction(**fossil_args, stratum_depth: 1)
      exc = engine.begin_excavation(target_stratum: 1)
      result = engine.excavate!(excavation_id: exc.id)
      expect(result).to be_a(
        Legion::Extensions::Agentic::Memory::Paleontology::Helpers::Fossil
      )
    end

    it 'returns nil when no fossils at stratum' do
      exc = engine.begin_excavation(target_stratum: 3)
      expect(engine.excavate!(excavation_id: exc.id)).to be_nil
    end

    it 'raises when excavation is completed' do
      exc = engine.begin_excavation(target_stratum: 0)
      exc.complete!
      expect do
        engine.excavate!(excavation_id: exc.id)
      end.to raise_error(ArgumentError, /already completed/)
    end
  end

  describe '#complete_excavation' do
    it 'completes the excavation' do
      exc = engine.begin_excavation(target_stratum: 0)
      result = engine.complete_excavation(excavation_id: exc.id)
      expect(result).to be_completed
    end
  end

  describe '#erode_all!' do
    it 'reduces preservation' do
      f = engine.record_extinction(**fossil_args)
      original = f.preservation
      engine.erode_all!
      expect(f.preservation).to be < original
    end

    it 'prunes fossils at 0.0' do
      f = engine.record_extinction(**fossil_args)
      f.instance_variable_set(:@preservation, 0.01)
      engine.erode_all!(rate: 0.5)
      expect(engine.all_fossils).not_to include(f)
    end
  end

  describe '#link_lineage' do
    it 'links two fossils' do
      f1 = engine.record_extinction(**fossil_args, content: 'child')
      f2 = engine.record_extinction(**fossil_args, content: 'parent')
      engine.link_lineage(fossil_id: f1.id, ancestor_id: f2.id)
      expect(f1.lineage_ids).to include(f2.id)
    end
  end

  describe '#fossils_by_type' do
    it 'filters correctly' do
      engine.record_extinction(**fossil_args)
      expect(engine.fossils_by_type(:strategy).size).to eq 1
      expect(engine.fossils_by_type(:pattern)).to be_empty
    end
  end

  describe '#fossils_by_cause' do
    it 'filters correctly' do
      engine.record_extinction(**fossil_args)
      expect(engine.fossils_by_cause(:obsolescence).size).to eq 1
    end
  end

  describe '#keystone_fossils' do
    it 'returns only keystones' do
      f = engine.record_extinction(**fossil_args, significance: 0.9)
      expect(engine.keystone_fossils).to include(f)
    end
  end

  describe '#mass_extinction?' do
    it 'returns false normally' do
      expect(engine.mass_extinction?).to be false
    end

    it 'returns true after many rapid extinctions' do
      6.times do
        engine.record_extinction(**fossil_args, content: SecureRandom.hex(4))
      end
      expect(engine.mass_extinction?(threshold: 5)).to be true
    end
  end

  describe '#paleontology_report' do
    it 'returns comprehensive report' do
      engine.record_extinction(**fossil_args)
      report = engine.paleontology_report
      %i[total_fossils total_excavations type_breakdown cause_breakdown
         era_breakdown avg_preservation avg_significance keystone_count
         imprint_count ancient_count mass_extinction].each do |key|
        expect(report).to have_key(key)
      end
    end

    it 'works empty' do
      expect(engine.paleontology_report[:total_fossils]).to eq 0
    end
  end
end
