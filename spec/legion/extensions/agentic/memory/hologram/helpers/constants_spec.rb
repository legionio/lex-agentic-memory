# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Hologram::Helpers::Constants do
  subject(:constants) { described_class }

  describe 'RESOLUTION_LEVELS' do
    it 'is a frozen array of symbols' do
      expect(described_class::RESOLUTION_LEVELS).to be_frozen
      expect(described_class::RESOLUTION_LEVELS).to all(be_a(Symbol))
    end

    it 'contains the expected levels in order' do
      expect(described_class::RESOLUTION_LEVELS).to eq(%i[perfect high medium low fragmentary])
    end
  end

  describe 'MAX_HOLOGRAMS' do
    it 'is 100' do
      expect(described_class::MAX_HOLOGRAMS).to eq(100)
    end
  end

  describe 'INTERFERENCE_DECAY' do
    it 'is 0.03' do
      expect(described_class::INTERFERENCE_DECAY).to eq(0.03)
    end
  end

  describe 'RECONSTRUCTION_THRESHOLD' do
    it 'is 0.3' do
      expect(described_class::RECONSTRUCTION_THRESHOLD).to eq(0.3)
    end
  end

  describe 'FRAGMENT_LABELS' do
    it 'is a frozen array' do
      expect(described_class::FRAGMENT_LABELS).to be_frozen
    end

    it 'maps 1.0 to :intact' do
      expect(described_class.label_for(described_class::FRAGMENT_LABELS, 1.0)).to eq(:intact)
    end

    it 'maps 0.95 to :intact' do
      expect(described_class.label_for(described_class::FRAGMENT_LABELS, 0.95)).to eq(:intact)
    end

    it 'maps 0.75 to :substantial' do
      expect(described_class.label_for(described_class::FRAGMENT_LABELS, 0.75)).to eq(:substantial)
    end

    it 'maps 0.55 to :partial' do
      expect(described_class.label_for(described_class::FRAGMENT_LABELS, 0.55)).to eq(:partial)
    end

    it 'maps 0.35 to :degraded' do
      expect(described_class.label_for(described_class::FRAGMENT_LABELS, 0.35)).to eq(:degraded)
    end

    it 'maps 0.1 to :fragmentary' do
      expect(described_class.label_for(described_class::FRAGMENT_LABELS, 0.1)).to eq(:fragmentary)
    end
  end

  describe 'RESOLUTION_LABELS' do
    it 'maps 0.95 to :perfect' do
      expect(described_class.label_for(described_class::RESOLUTION_LABELS, 0.95)).to eq(:perfect)
    end

    it 'maps 0.75 to :high' do
      expect(described_class.label_for(described_class::RESOLUTION_LABELS, 0.75)).to eq(:high)
    end

    it 'maps 0.55 to :medium' do
      expect(described_class.label_for(described_class::RESOLUTION_LABELS, 0.55)).to eq(:medium)
    end

    it 'maps 0.35 to :low' do
      expect(described_class.label_for(described_class::RESOLUTION_LABELS, 0.35)).to eq(:low)
    end

    it 'maps 0.1 to :fragmentary' do
      expect(described_class.label_for(described_class::RESOLUTION_LABELS, 0.1)).to eq(:fragmentary)
    end
  end

  describe 'FIDELITY_LABELS' do
    it 'maps 0.9 to :pristine' do
      expect(described_class.label_for(described_class::FIDELITY_LABELS, 0.9)).to eq(:pristine)
    end

    it 'maps 0.65 to :clear' do
      expect(described_class.label_for(described_class::FIDELITY_LABELS, 0.65)).to eq(:clear)
    end

    it 'maps 0.45 to :hazy' do
      expect(described_class.label_for(described_class::FIDELITY_LABELS, 0.45)).to eq(:hazy)
    end

    it 'maps 0.25 to :clouded' do
      expect(described_class.label_for(described_class::FIDELITY_LABELS, 0.25)).to eq(:clouded)
    end

    it 'maps 0.1 to :corrupted' do
      expect(described_class.label_for(described_class::FIDELITY_LABELS, 0.1)).to eq(:corrupted)
    end
  end

  describe 'INTERFERENCE_LABELS' do
    it 'maps 0.8 to :strong' do
      expect(described_class.label_for(described_class::INTERFERENCE_LABELS, 0.8)).to eq(:strong)
    end

    it 'maps 0.5 to :moderate' do
      expect(described_class.label_for(described_class::INTERFERENCE_LABELS, 0.5)).to eq(:moderate)
    end

    it 'maps 0.2 to :weak' do
      expect(described_class.label_for(described_class::INTERFERENCE_LABELS, 0.2)).to eq(:weak)
    end

    it 'maps 0.05 to :negligible' do
      expect(described_class.label_for(described_class::INTERFERENCE_LABELS, 0.05)).to eq(:negligible)
    end
  end

  describe '.label_for' do
    it 'returns a symbol' do
      label = described_class.label_for(described_class::RESOLUTION_LABELS, 0.5)
      expect(label).to be_a(Symbol)
    end

    it 'falls back to last label for values below all ranges' do
      label = described_class.label_for(described_class::RESOLUTION_LABELS, -0.1)
      expect(label).to eq(:fragmentary)
    end

    it 'matches the first matching range' do
      label = described_class.label_for(described_class::RESOLUTION_LABELS, 1.0)
      expect(label).to eq(:perfect)
    end
  end
end
