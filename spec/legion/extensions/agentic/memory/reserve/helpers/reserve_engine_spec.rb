# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Reserve::Helpers::ReserveEngine do
  subject(:engine) { described_class.new }

  let(:constants) { Legion::Extensions::Agentic::Memory::Reserve::Helpers::Constants }

  describe '#initialize' do
    it 'starts with empty pathways' do
      expect(engine.pathways).to be_empty
    end

    it 'starts with empty history' do
      expect(engine.history).to be_empty
    end
  end

  describe '#add_pathway' do
    it 'creates a pathway' do
      pathway = engine.add_pathway(function: :reasoning)
      expect(pathway).to be_a(Legion::Extensions::Agentic::Memory::Reserve::Helpers::Pathway)
    end

    it 'stores the pathway' do
      pathway = engine.add_pathway(function: :memory)
      expect(engine.pathways[pathway.id]).to be(pathway)
    end

    it 'respects limit' do
      constants::MAX_PATHWAYS.times { |i| engine.add_pathway(function: :"fn_#{i}") }
      expect(engine.add_pathway(function: :overflow)).to be_nil
    end
  end

  describe '#link_backup' do
    let!(:primary) { engine.add_pathway(function: :reasoning) }
    let!(:backup) { engine.add_pathway(function: :reasoning_backup) }

    it 'links backup to primary' do
      engine.link_backup(primary_id: primary.id, backup_id: backup.id)
      expect(primary.backup_ids).to include(backup.id)
    end

    it 'returns nil for unknown IDs' do
      expect(engine.link_backup(primary_id: :nonexistent, backup_id: backup.id)).to be_nil
    end
  end

  describe '#damage_pathway' do
    let!(:pathway) { engine.add_pathway(function: :reasoning) }

    it 'reduces capacity' do
      engine.damage_pathway(pathway_id: pathway.id, amount: 0.3)
      expect(pathway.capacity).to eq(0.7)
    end

    it 'returns nil for unknown ID' do
      expect(engine.damage_pathway(pathway_id: :nonexistent, amount: 0.1)).to be_nil
    end

    it 'triggers compensation when degraded with backup' do
      backup = engine.add_pathway(function: :backup)
      engine.link_backup(primary_id: pathway.id, backup_id: backup.id)
      engine.damage_pathway(pathway_id: pathway.id, amount: 0.7)
      expect(pathway.compensation_count).to be >= 1
    end
  end

  describe '#recover_pathway' do
    let!(:pathway) { engine.add_pathway(function: :reasoning) }

    it 'increases capacity' do
      engine.damage_pathway(pathway_id: pathway.id, amount: 0.5)
      original = pathway.capacity
      engine.recover_pathway(pathway_id: pathway.id, amount: 0.1)
      expect(pathway.capacity).to be > original
    end
  end

  describe '#effective_capacity' do
    it 'returns capacity with compensation' do
      primary = engine.add_pathway(function: :reasoning)
      backup = engine.add_pathway(function: :backup)
      engine.link_backup(primary_id: primary.id, backup_id: backup.id)
      engine.damage_pathway(pathway_id: primary.id, amount: 0.7)
      expect(engine.effective_capacity(pathway_id: primary.id)).to be > primary.capacity
    end

    it 'returns nil for unknown ID' do
      expect(engine.effective_capacity(pathway_id: :nonexistent)).to be_nil
    end
  end

  describe '#overall_reserve' do
    it 'returns 1.0 when empty' do
      expect(engine.overall_reserve).to eq(1.0)
    end

    it 'decreases when pathways are damaged' do
      p = engine.add_pathway(function: :test)
      engine.damage_pathway(pathway_id: p.id, amount: 0.5)
      expect(engine.overall_reserve).to be < 1.0
    end
  end

  describe '#reserve_label' do
    it 'returns :robust when healthy' do
      engine.add_pathway(function: :test)
      expect(engine.reserve_label).to eq(:robust)
    end

    it 'returns worse labels when damaged' do
      p = engine.add_pathway(function: :test)
      engine.damage_pathway(pathway_id: p.id, amount: 0.8)
      expect(%i[vulnerable critical reduced]).to include(engine.reserve_label)
    end
  end

  describe '#degraded_pathways' do
    it 'returns empty when all healthy' do
      engine.add_pathway(function: :test)
      expect(engine.degraded_pathways).to be_empty
    end

    it 'returns degraded pathways' do
      p = engine.add_pathway(function: :test)
      engine.damage_pathway(pathway_id: p.id, amount: 0.6)
      expect(engine.degraded_pathways.size).to eq(1)
    end
  end

  describe '#domain_reserve' do
    it 'computes reserve for specific domain' do
      engine.add_pathway(function: :reasoning, domain: :cognition)
      engine.add_pathway(function: :emotion, domain: :affect)
      expect(engine.domain_reserve(domain: :cognition)).to eq(1.0)
    end

    it 'returns default for unknown domain' do
      expect(engine.domain_reserve(domain: :nonexistent)).to eq(1.0)
    end
  end

  describe '#most_vulnerable' do
    it 'returns pathways sorted by capacity ascending' do
      healthy = engine.add_pathway(function: :healthy)
      weak = engine.add_pathway(function: :weak)
      engine.damage_pathway(pathway_id: weak.id, amount: 0.7)
      result = engine.most_vulnerable(limit: 2)
      expect(result.first[:capacity]).to be <= result.last[:capacity]
      expect(result.first[:function]).to eq(weak.function)
      expect(result.last[:function]).to eq(healthy.function)
    end
  end

  describe '#most_redundant' do
    it 'returns pathways sorted by backup count descending' do
      redundant = engine.add_pathway(function: :main)
      simple = engine.add_pathway(function: :simple)
      backup = engine.add_pathway(function: :backup)
      engine.link_backup(primary_id: redundant.id, backup_id: backup.id)
      result = engine.most_redundant(limit: 3)
      expect(result.first[:backup_count]).to be >= result.last[:backup_count]
      expect(result.first[:function]).to eq(redundant.function)
      expect(result.last[:function]).to eq(simple.function).or eq(backup.function)
    end
  end

  describe '#recover_all' do
    it 'recovers non-failed pathways' do
      p = engine.add_pathway(function: :test)
      engine.damage_pathway(pathway_id: p.id, amount: 0.3)
      original = p.capacity
      engine.recover_all
      expect(p.capacity).to be > original
    end

    it 'does not recover failed pathways' do
      p = engine.add_pathway(function: :test)
      engine.damage_pathway(pathway_id: p.id, amount: 0.95)
      original = p.capacity
      engine.recover_all
      expect(p.capacity).to eq(original)
    end
  end

  describe '#to_h' do
    it 'returns stats hash' do
      h = engine.to_h
      expect(h).to include(
        :pathway_count, :overall_reserve, :reserve_label,
        :healthy_count, :degraded_count, :failed_count, :history_size
      )
    end
  end
end
