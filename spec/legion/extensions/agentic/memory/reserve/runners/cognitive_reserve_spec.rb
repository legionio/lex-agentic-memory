# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Reserve::Runners::CognitiveReserve do
  let(:runner_host) do
    Object.new.tap { |o| o.extend(described_class) }
  end

  describe '#add_cognitive_pathway' do
    it 'creates a pathway' do
      result = runner_host.add_cognitive_pathway(function: :reasoning)
      expect(result[:success]).to be true
      expect(result[:pathway_id]).to be_a(Symbol)
    end
  end

  describe '#link_backup_pathway' do
    it 'links a backup' do
      primary = runner_host.add_cognitive_pathway(function: :main)
      backup = runner_host.add_cognitive_pathway(function: :backup)
      result = runner_host.link_backup_pathway(
        primary_id: primary[:pathway_id],
        backup_id:  backup[:pathway_id]
      )
      expect(result[:success]).to be true
      expect(result[:backup_count]).to eq(1)
    end

    it 'returns failure for unknown IDs' do
      result = runner_host.link_backup_pathway(primary_id: :fake, backup_id: :fake)
      expect(result[:success]).to be false
    end
  end

  describe '#damage_cognitive_pathway' do
    it 'damages and returns state' do
      pathway = runner_host.add_cognitive_pathway(function: :test)
      result = runner_host.damage_cognitive_pathway(pathway_id: pathway[:pathway_id], amount: 0.3)
      expect(result[:success]).to be true
      expect(result[:capacity]).to eq(0.7)
    end

    it 'returns failure for unknown ID' do
      result = runner_host.damage_cognitive_pathway(pathway_id: :fake, amount: 0.1)
      expect(result[:success]).to be false
    end
  end

  describe '#recover_cognitive_pathway' do
    it 'recovers capacity' do
      pathway = runner_host.add_cognitive_pathway(function: :test)
      runner_host.damage_cognitive_pathway(pathway_id: pathway[:pathway_id], amount: 0.5)
      result = runner_host.recover_cognitive_pathway(pathway_id: pathway[:pathway_id], amount: 0.1)
      expect(result[:success]).to be true
      expect(result[:capacity]).to eq(0.6)
    end
  end

  describe '#cognitive_reserve_assessment' do
    it 'returns assessment with expected keys' do
      result = runner_host.cognitive_reserve_assessment
      expect(result[:success]).to be true
      expect(result).to include(:overall_reserve, :reserve_label, :most_vulnerable, :degraded, :failed)
    end
  end

  describe '#domain_cognitive_reserve' do
    it 'returns domain-specific reserve' do
      runner_host.add_cognitive_pathway(function: :reasoning, domain: :cognition)
      result = runner_host.domain_cognitive_reserve(domain: :cognition)
      expect(result[:success]).to be true
      expect(result[:domain]).to eq(:cognition)
    end
  end

  describe '#most_redundant_pathways' do
    it 'returns pathways sorted by redundancy' do
      result = runner_host.most_redundant_pathways
      expect(result[:success]).to be true
    end
  end

  describe '#update_cognitive_reserve' do
    it 'runs recovery and returns stats' do
      result = runner_host.update_cognitive_reserve
      expect(result[:success]).to be true
      expect(result).to include(:pathway_count, :overall_reserve)
    end
  end

  describe '#cognitive_reserve_stats' do
    it 'returns stats' do
      result = runner_host.cognitive_reserve_stats
      expect(result[:success]).to be true
    end
  end
end
