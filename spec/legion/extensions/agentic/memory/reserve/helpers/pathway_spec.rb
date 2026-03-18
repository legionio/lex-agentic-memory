# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Reserve::Helpers::Pathway do
  subject(:pathway) do
    described_class.new(id: :path_one, function: :reasoning, domain: :cognition)
  end

  let(:constants) { Legion::Extensions::Agentic::Memory::Reserve::Helpers::Constants }

  describe '#initialize' do
    it 'sets id' do
      expect(pathway.id).to eq(:path_one)
    end

    it 'sets function' do
      expect(pathway.function).to eq(:reasoning)
    end

    it 'sets domain' do
      expect(pathway.domain).to eq(:cognition)
    end

    it 'starts at full capacity' do
      expect(pathway.capacity).to eq(1.0)
    end

    it 'starts healthy' do
      expect(pathway.state).to eq(:healthy)
    end

    it 'starts with empty backups' do
      expect(pathway.backup_ids).to be_empty
    end

    it 'clamps capacity above ceiling' do
      p = described_class.new(id: :x, function: :test, capacity: 1.5)
      expect(p.capacity).to eq(constants::CAPACITY_CEILING)
    end

    it 'clamps capacity below floor' do
      p = described_class.new(id: :x, function: :test, capacity: -0.5)
      expect(p.capacity).to eq(constants::CAPACITY_FLOOR)
    end
  end

  describe '#damage' do
    it 'reduces capacity' do
      pathway.damage(amount: 0.3)
      expect(pathway.capacity).to eq(0.7)
    end

    it 'increments damage count' do
      pathway.damage(amount: 0.1)
      expect(pathway.damage_count).to eq(1)
    end

    it 'clamps at floor' do
      pathway.damage(amount: 2.0)
      expect(pathway.capacity).to eq(0.0)
    end

    it 'returns self for chaining' do
      expect(pathway.damage(amount: 0.1)).to be(pathway)
    end
  end

  describe '#recover' do
    before { pathway.damage(amount: 0.5) }

    it 'increases capacity' do
      original = pathway.capacity
      pathway.recover(amount: 0.1)
      expect(pathway.capacity).to be > original
    end

    it 'clamps at ceiling' do
      pathway.recover(amount: 2.0)
      expect(pathway.capacity).to eq(1.0)
    end
  end

  describe '#add_backup' do
    it 'adds a backup pathway ID' do
      pathway.add_backup(pathway_id: :backup_one)
      expect(pathway.backup_ids).to include(:backup_one)
    end

    it 'ignores duplicates' do
      pathway.add_backup(pathway_id: :backup_one)
      pathway.add_backup(pathway_id: :backup_one)
      expect(pathway.backup_ids.size).to eq(1)
    end
  end

  describe '#remove_backup' do
    it 'removes a backup' do
      pathway.add_backup(pathway_id: :backup_one)
      pathway.remove_backup(pathway_id: :backup_one)
      expect(pathway.backup_ids).to be_empty
    end
  end

  describe '#state' do
    it 'is :healthy at full capacity' do
      expect(pathway.state).to eq(:healthy)
    end

    it 'is :degraded below threshold without backups' do
      pathway.damage(amount: 0.6)
      expect(pathway.state).to eq(:degraded)
    end

    it 'is :compensating below threshold with backups' do
      pathway.add_backup(pathway_id: :backup_one)
      pathway.damage(amount: 0.6)
      expect(pathway.state).to eq(:compensating)
    end

    it 'is :failed at very low capacity' do
      pathway.damage(amount: 0.95)
      expect(pathway.state).to eq(:failed)
    end
  end

  describe '#effective_capacity' do
    it 'returns raw capacity when healthy' do
      expect(pathway.effective_capacity).to eq(1.0)
    end

    it 'compensates when degraded with backup capacities' do
      pathway.damage(amount: 0.7)
      effective = pathway.effective_capacity(backup_capacities: [0.8])
      expect(effective).to be > pathway.capacity
    end

    it 'does not exceed threshold with compensation' do
      pathway.damage(amount: 0.6)
      effective = pathway.effective_capacity(backup_capacities: [1.0, 1.0])
      expect(effective).to be <= constants::CAPACITY_CEILING
    end
  end

  describe '#redundancy' do
    it 'returns zero with no backups' do
      expect(pathway.redundancy).to eq(0)
    end

    it 'returns backup count' do
      pathway.add_backup(pathway_id: :a)
      pathway.add_backup(pathway_id: :b)
      expect(pathway.redundancy).to eq(2)
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      h = pathway.to_h
      expect(h).to include(
        :id, :function, :domain, :capacity, :state,
        :backup_count, :backup_ids, :damage_count,
        :compensation_count, :created_at, :updated_at
      )
    end
  end
end
