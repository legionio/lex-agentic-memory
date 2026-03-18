# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::ImmuneMemory::Helpers::Encounter do
  subject(:encounter) do
    described_class.new(threat_type: :prompt_injection, threat_signature: 'sig-001', severity: 0.7)
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(encounter.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores threat_type' do
      expect(encounter.threat_type).to eq(:prompt_injection)
    end

    it 'stores threat_signature' do
      expect(encounter.threat_signature).to eq('sig-001')
    end

    it 'stores severity' do
      expect(encounter.severity).to eq(0.7)
    end

    it 'defaults response_type to primary' do
      expect(encounter.response_type).to eq(:primary)
    end

    it 'defaults outcome to neutralized' do
      expect(encounter.outcome).to eq(:neutralized)
    end
  end

  describe '#secondary?' do
    it 'is false for primary' do
      expect(encounter.secondary?).to be false
    end

    it 'is true for secondary' do
      sec = described_class.new(threat_type: :logic_manipulation, threat_signature: 's',
                                response_type: :secondary)
      expect(sec.secondary?).to be true
    end
  end

  describe '#primary?' do
    it 'is true for primary' do
      expect(encounter.primary?).to be true
    end
  end

  describe '#neutralized?' do
    it 'is true when neutralized' do
      expect(encounter.neutralized?).to be true
    end
  end

  describe '#evaded?' do
    it 'is true when evaded' do
      evaded = described_class.new(threat_type: :data_poisoning, threat_signature: 's', outcome: :evaded)
      expect(evaded.evaded?).to be true
    end
  end

  describe '#critical?' do
    it 'is false for moderate severity' do
      expect(encounter.critical?).to be false
    end

    it 'is true for high severity' do
      crit = described_class.new(threat_type: :resource_exhaustion, threat_signature: 's', severity: 0.9)
      expect(crit.critical?).to be true
    end
  end

  describe '#to_h' do
    it 'includes all fields' do
      hash = encounter.to_h
      expect(hash).to include(
        :id, :threat_type, :threat_signature, :severity,
        :response_type, :response_speed, :outcome, :critical, :created_at
      )
    end
  end
end
