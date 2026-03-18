# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Paleontology::Helpers::Constants do
  let(:c) { described_class }

  it 'defines MAX_FOSSILS' do
    expect(c::MAX_FOSSILS).to eq 500
  end

  it 'has 8 fossil types' do
    expect(c::FOSSIL_TYPES.size).to eq 8
  end

  it 'has 6 extinction causes' do
    expect(c::EXTINCTION_CAUSES.size).to eq 6
  end

  it 'has 8 era names' do
    expect(c::ERA_NAMES.size).to eq 8
  end

  describe '.label_for' do
    it 'returns matching preservation label' do
      expect(c.label_for(c::PRESERVATION_LABELS, 0.9)).to eq :pristine
      expect(c.label_for(c::PRESERVATION_LABELS, 0.1)).to eq :imprint
    end

    it 'returns matching significance label' do
      expect(c.label_for(c::SIGNIFICANCE_LABELS, 0.9)).to eq :keystone
      expect(c.label_for(c::SIGNIFICANCE_LABELS, 0.1)).to eq :trivial
    end
  end
end
