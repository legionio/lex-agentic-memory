# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Hologram::Helpers::HolographicFragment do
  let(:parent_id) { SecureRandom.uuid }
  let(:content)   { 'the cat sat on the mat' }

  subject(:fragment) do
    described_class.new(content: content, parent_hologram_id: parent_id)
  end

  describe '#initialize' do
    it 'generates a UUID id' do
      expect(fragment.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores content' do
      expect(fragment.content).to eq(content)
    end

    it 'stores parent_hologram_id' do
      expect(fragment.parent_hologram_id).to eq(parent_id)
    end

    it 'defaults completeness to 1.0' do
      expect(fragment.completeness).to eq(1.0)
    end

    it 'defaults fidelity to 1.0' do
      expect(fragment.fidelity).to eq(1.0)
    end

    it 'clamps completeness above 1.0' do
      f = described_class.new(content: content, parent_hologram_id: parent_id, completeness: 1.5)
      expect(f.completeness).to eq(1.0)
    end

    it 'clamps completeness below 0.0' do
      f = described_class.new(content: content, parent_hologram_id: parent_id, completeness: -0.5)
      expect(f.completeness).to eq(0.0)
    end

    it 'clamps fidelity above 1.0' do
      f = described_class.new(content: content, parent_hologram_id: parent_id, fidelity: 2.0)
      expect(f.fidelity).to eq(1.0)
    end

    it 'clamps fidelity below 0.0' do
      f = described_class.new(content: content, parent_hologram_id: parent_id, fidelity: -1.0)
      expect(f.fidelity).to eq(0.0)
    end

    it 'sets created_at to a Time object' do
      expect(fragment.created_at).to be_a(Time)
    end
  end

  describe '#degrade!' do
    it 'reduces completeness by INTERFERENCE_DECAY' do
      original = fragment.completeness
      fragment.degrade!
      expect(fragment.completeness).to be < original
    end

    it 'reduces fidelity by INTERFERENCE_DECAY' do
      original = fragment.fidelity
      fragment.degrade!
      expect(fragment.fidelity).to be < original
    end

    it 'uses default decay rate when no argument given' do
      original = fragment.completeness
      fragment.degrade!
      expected = (original - Legion::Extensions::Agentic::Memory::Hologram::Helpers::Constants::INTERFERENCE_DECAY).round(10)
      expect(fragment.completeness).to be_within(0.0001).of(expected)
    end

    it 'accepts a custom decay rate' do
      original = fragment.completeness
      fragment.degrade!(0.1)
      expect(fragment.completeness).to be_within(0.0001).of(original - 0.1)
    end

    it 'does not go below 0.0' do
      10.times { fragment.degrade!(0.2) }
      expect(fragment.completeness).to eq(0.0)
    end

    it 'returns self for chaining' do
      expect(fragment.degrade!).to eq(fragment)
    end
  end

  describe '#enhance!' do
    let(:low_fragment) do
      described_class.new(content: content, parent_hologram_id: parent_id, completeness: 0.5, fidelity: 0.5)
    end

    it 'increases completeness' do
      original = low_fragment.completeness
      low_fragment.enhance!
      expect(low_fragment.completeness).to be > original
    end

    it 'increases fidelity' do
      original = low_fragment.fidelity
      low_fragment.enhance!
      expect(low_fragment.fidelity).to be > original
    end

    it 'accepts a custom boost' do
      original = low_fragment.completeness
      low_fragment.enhance!(0.2)
      expect(low_fragment.completeness).to be_within(0.0001).of(original + 0.2)
    end

    it 'does not exceed 1.0' do
      3.times { fragment.enhance!(0.5) }
      expect(fragment.completeness).to eq(1.0)
    end

    it 'returns self for chaining' do
      expect(low_fragment.enhance!).to eq(low_fragment)
    end
  end

  describe '#sufficient?' do
    it 'returns true when completeness exceeds RECONSTRUCTION_THRESHOLD' do
      f = described_class.new(content: content, parent_hologram_id: parent_id, completeness: 0.5)
      expect(f.sufficient?).to be true
    end

    it 'returns false when completeness is at threshold' do
      threshold = Legion::Extensions::Agentic::Memory::Hologram::Helpers::Constants::RECONSTRUCTION_THRESHOLD
      f = described_class.new(content: content, parent_hologram_id: parent_id, completeness: threshold)
      expect(f.sufficient?).to be false
    end

    it 'returns false when completeness is below threshold' do
      f = described_class.new(content: content, parent_hologram_id: parent_id, completeness: 0.1)
      expect(f.sufficient?).to be false
    end
  end

  describe '#completeness_label' do
    it 'returns a symbol' do
      expect(fragment.completeness_label).to be_a(Symbol)
    end

    it 'returns :intact for completeness 1.0' do
      expect(fragment.completeness_label).to eq(:intact)
    end

    it 'returns :fragmentary for very low completeness' do
      f = described_class.new(content: content, parent_hologram_id: parent_id, completeness: 0.1)
      expect(f.completeness_label).to eq(:fragmentary)
    end
  end

  describe '#fidelity_label' do
    it 'returns a symbol' do
      expect(fragment.fidelity_label).to be_a(Symbol)
    end

    it 'returns :pristine for fidelity 1.0' do
      expect(fragment.fidelity_label).to eq(:pristine)
    end

    it 'returns :corrupted for very low fidelity' do
      f = described_class.new(content: content, parent_hologram_id: parent_id, fidelity: 0.1)
      expect(f.fidelity_label).to eq(:corrupted)
    end
  end

  describe '#to_h' do
    subject(:hash) { fragment.to_h }

    it 'includes :id' do
      expect(hash[:id]).to eq(fragment.id)
    end

    it 'includes :parent_hologram_id' do
      expect(hash[:parent_hologram_id]).to eq(parent_id)
    end

    it 'includes :content' do
      expect(hash[:content]).to eq(content)
    end

    it 'includes :completeness' do
      expect(hash[:completeness]).to eq(fragment.completeness)
    end

    it 'includes :fidelity' do
      expect(hash[:fidelity]).to eq(fragment.fidelity)
    end

    it 'includes :completeness_label as symbol' do
      expect(hash[:completeness_label]).to be_a(Symbol)
    end

    it 'includes :fidelity_label as symbol' do
      expect(hash[:fidelity_label]).to be_a(Symbol)
    end

    it 'includes :sufficient as boolean' do
      expect(hash[:sufficient]).to be(true).or be(false)
    end

    it 'includes :created_at as ISO8601 string' do
      expect(hash[:created_at]).to match(/\d{4}-\d{2}-\d{2}T/)
    end
  end
end
