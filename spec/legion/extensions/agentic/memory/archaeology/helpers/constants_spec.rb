# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Archaeology::Helpers::Constants do
  let(:c) { described_class }

  it 'defines MAX_ARTIFACTS' do
    expect(c::MAX_ARTIFACTS).to eq 500
  end

  it 'defines MAX_SITES' do
    expect(c::MAX_SITES).to eq 50
  end

  it 'has 8 artifact types' do
    expect(c::ARTIFACT_TYPES.size).to eq 8
  end

  it 'has 8 domain types' do
    expect(c::DOMAIN_TYPES.size).to eq 8
  end

  it 'has 5 depth levels' do
    expect(c::EXCAVATION_DEPTH_LEVELS.size).to eq 5
  end

  it 'has depth rarity weights for each level' do
    c::EXCAVATION_DEPTH_LEVELS.each do |level|
      expect(c::DEPTH_RARITY_WEIGHTS).to have_key(level)
    end
  end

  describe '.label_for' do
    it 'returns matching label' do
      expect(c.label_for(c::PRESERVATION_LABELS, 0.1)).to eq :dust
      expect(c.label_for(c::PRESERVATION_LABELS, 0.9)).to eq :pristine
    end

    it 'returns last label for out-of-range' do
      expect(c.label_for(c::PRESERVATION_LABELS, 999)).to eq :pristine
    end
  end
end
