# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::ImmuneMemory::Helpers::MemoryCell do
  subject(:cell) { described_class.new(threat_type: :prompt_injection, signature: 'sig-001') }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(cell.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores threat_type' do
      expect(cell.threat_type).to eq(:prompt_injection)
    end

    it 'stores signature' do
      expect(cell.signature).to eq('sig-001')
    end

    it 'defaults cell_type to :b_memory' do
      expect(cell.cell_type).to eq(:b_memory)
    end

    it 'defaults strength to VACCINATION_STRENGTH' do
      expect(cell.strength).to eq(0.5)
    end

    it 'clamps strength' do
      high = described_class.new(threat_type: :logic_manipulation, signature: 's', strength: 5.0)
      expect(high.strength).to eq(1.0)
    end

    it 'validates cell_type' do
      bad = described_class.new(threat_type: :logic_manipulation, signature: 's', cell_type: :invalid)
      expect(bad.cell_type).to eq(:b_memory)
    end

    it 'starts with 0 encounters' do
      expect(cell.encounter_count).to eq(0)
    end
  end

  describe '#activate!' do
    it 'increases strength' do
      original = cell.strength
      cell.activate!
      expect(cell.strength).to be > original
    end

    it 'increments encounter_count' do
      cell.activate!
      expect(cell.encounter_count).to eq(1)
    end

    it 'resets decay_cycles' do
      cell.decay!
      cell.activate!
      expect(cell.decay_cycles).to eq(0)
    end
  end

  describe '#decay!' do
    it 'decreases strength' do
      original = cell.strength
      cell.decay!
      expect(cell.strength).to be < original
    end

    it 'increments decay_cycles' do
      cell.decay!
      expect(cell.decay_cycles).to eq(1)
    end

    it 'clamps at 0.0' do
      200.times { cell.decay! }
      expect(cell.strength).to eq(0.0)
    end
  end

  describe '#recognizes?' do
    it 'recognizes matching signature when strong enough' do
      cell.activate!
      cell.activate!
      expect(cell.recognizes?('sig-001')).to be true
    end

    it 'does not recognize different signature' do
      cell.activate!
      cell.activate!
      expect(cell.recognizes?('sig-999')).to be false
    end

    it 'does not recognize when strength is too low' do
      80.times { cell.decay! }
      expect(cell.recognizes?('sig-001')).to be false
    end
  end

  describe '#t_cell?' do
    it 'is true for t_helper' do
      t = described_class.new(threat_type: :data_poisoning, signature: 's', cell_type: :t_helper)
      expect(t.t_cell?).to be true
    end

    it 'is false for b_memory' do
      expect(cell.t_cell?).to be false
    end
  end

  describe '#b_cell?' do
    it 'is true for b_memory' do
      expect(cell.b_cell?).to be true
    end

    it 'is true for b_plasma' do
      bp = described_class.new(threat_type: :data_poisoning, signature: 's', cell_type: :b_plasma)
      expect(bp.b_cell?).to be true
    end
  end

  describe '#expired?' do
    it 'is false at default strength' do
      expect(cell.expired?).to be false
    end

    it 'is true when fully decayed' do
      200.times { cell.decay! }
      expect(cell.expired?).to be true
    end
  end

  describe '#veteran?' do
    it 'is false initially' do
      expect(cell.veteran?).to be false
    end

    it 'is true after 5 encounters' do
      5.times { cell.activate! }
      expect(cell.veteran?).to be true
    end
  end

  describe '#naive?' do
    it 'is true initially' do
      expect(cell.naive?).to be true
    end

    it 'is false after activation' do
      cell.activate!
      expect(cell.naive?).to be false
    end
  end

  describe '#response_speed' do
    it 'returns primary speed when naive' do
      expect(cell.response_speed).to eq(1.0)
    end

    it 'returns faster speed after encounters' do
      3.times { cell.activate! }
      expect(cell.response_speed).to be > 1.0
    end

    it 'caps at secondary response speed' do
      10.times { cell.activate! }
      expect(cell.response_speed).to eq(3.0)
    end
  end

  describe '#maturity' do
    it 'is 0.0 when naive' do
      expect(cell.maturity).to eq(0.0)
    end

    it 'increases with encounters' do
      5.times { cell.activate! }
      expect(cell.maturity).to eq(0.5)
    end
  end

  describe '#to_h' do
    it 'includes all fields' do
      hash = cell.to_h
      expect(hash).to include(
        :id, :threat_type, :signature, :cell_type, :strength,
        :encounter_count, :decay_cycles, :response_speed,
        :immunity_label, :maturity_label, :t_cell, :b_cell, :expired, :created_at
      )
    end
  end
end
