# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Paleontology::Helpers::Fossil do
  let(:fossil) do
    described_class.new(fossil_type: :strategy, domain: :cognitive,
                        content: 'old approach', extinction_cause: :obsolescence)
  end

  describe '#initialize' do
    it 'assigns a UUID' do
      expect(fossil.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets fossil_type' do
      expect(fossil.fossil_type).to eq :strategy
    end

    it 'sets domain' do
      expect(fossil.domain).to eq :cognitive
    end

    it 'sets extinction_cause' do
      expect(fossil.extinction_cause).to eq :obsolescence
    end

    it 'defaults preservation to 0.8' do
      expect(fossil.preservation).to eq 0.8
    end

    it 'defaults significance to 0.5' do
      expect(fossil.significance).to eq 0.5
    end

    it 'assigns an era' do
      expect(fossil.era).to be_a Symbol
    end

    it 'raises on invalid fossil_type' do
      expect do
        described_class.new(fossil_type: :bogus, domain: :cognitive,
                            content: 'x', extinction_cause: :obsolescence)
      end.to raise_error(ArgumentError, /unknown fossil type/)
    end

    it 'raises on invalid extinction_cause' do
      expect do
        described_class.new(fossil_type: :strategy, domain: :cognitive,
                            content: 'x', extinction_cause: :bogus)
      end.to raise_error(ArgumentError, /unknown extinction cause/)
    end

    it 'clamps stratum_depth to 0..4' do
      f = described_class.new(fossil_type: :pattern, domain: :semantic,
                              content: 'x', extinction_cause: :irrelevance,
                              stratum_depth: 99)
      expect(f.stratum_depth).to eq 4
    end
  end

  describe '#erode!' do
    it 'reduces preservation' do
      original = fossil.preservation
      fossil.erode!
      expect(fossil.preservation).to be < original
    end

    it 'clamps at 0.0' do
      50.times { fossil.erode!(rate: 0.1) }
      expect(fossil.preservation).to eq 0.0
    end

    it 'returns self' do
      expect(fossil.erode!).to eq fossil
    end
  end

  describe '#reinforce!' do
    it 'increases significance' do
      original = fossil.significance
      fossil.reinforce!(boost: 0.2)
      expect(fossil.significance).to be > original
    end

    it 'clamps at 1.0' do
      fossil.reinforce!(boost: 5.0)
      expect(fossil.significance).to eq 1.0
    end
  end

  describe '#imprint?' do
    it 'returns true when preservation < 0.2' do
      fossil.instance_variable_set(:@preservation, 0.1)
      expect(fossil.imprint?).to be true
    end

    it 'returns false otherwise' do
      expect(fossil.imprint?).to be false
    end
  end

  describe '#keystone?' do
    it 'returns true when significance >= 0.8' do
      fossil.instance_variable_set(:@significance, 0.9)
      expect(fossil.keystone?).to be true
    end

    it 'returns false otherwise' do
      expect(fossil.keystone?).to be false
    end
  end

  describe '#link_lineage' do
    it 'adds ancestor' do
      fossil.link_lineage('ancestor-id')
      expect(fossil.lineage_ids).to include('ancestor-id')
    end

    it 'does not duplicate' do
      fossil.link_lineage('same')
      fossil.link_lineage('same')
      expect(fossil.lineage_ids.count('same')).to eq 1
    end
  end

  describe '#to_h' do
    it 'includes all fields' do
      %i[id fossil_type domain content extinction_cause era stratum_depth
         preservation significance discovered_at extinct_at lineage_ids
         imprint keystone ancient].each do |key|
        expect(fossil.to_h).to have_key(key)
      end
    end
  end
end
