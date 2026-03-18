# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Archaeology::Helpers::Artifact do
  let(:artifact) do
    described_class.new(
      type: :pattern, domain: :cognitive,
      content: 'test content', depth_level: :surface
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(artifact.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets artifact_type as symbol' do
      expect(artifact.artifact_type).to eq :pattern
    end

    it 'sets domain' do
      expect(artifact.domain).to eq :cognitive
    end

    it 'sets content as string' do
      expect(artifact.content).to eq 'test content'
    end

    it 'sets depth_level' do
      expect(artifact.depth_level).to eq :surface
    end

    it 'defaults preservation to DEFAULT_PRESERVATION' do
      expect(artifact.preservation_quality).to be_within(0.01).of(0.5)
    end

    it 'allows custom preservation' do
      a = described_class.new(type: :skill, domain: :emotional,
                              content: 'x', depth_level: :deep, preservation: 0.9)
      expect(a.preservation_quality).to eq 0.9
    end

    it 'clamps preservation to 0.0..1.0' do
      a = described_class.new(type: :skill, domain: :emotional,
                              content: 'x', depth_level: :surface, preservation: 1.5)
      expect(a.preservation_quality).to eq 1.0
    end

    it 'sets discovered_at' do
      expect(artifact.discovered_at).to be_a Time
    end

    it 'sets origin_epoch' do
      expect(artifact.origin_epoch).to be_a Time
    end

    it 'initializes empty contextual_links' do
      expect(artifact.contextual_links).to eq []
    end

    it 'raises on invalid type' do
      expect do
        described_class.new(type: :bogus, domain: :cognitive,
                            content: 'x', depth_level: :surface)
      end.to raise_error(ArgumentError, /unknown artifact type/)
    end

    it 'raises on invalid domain' do
      expect do
        described_class.new(type: :pattern, domain: :bogus,
                            content: 'x', depth_level: :surface)
      end.to raise_error(ArgumentError, /unknown domain/)
    end

    it 'raises on invalid depth_level' do
      expect do
        described_class.new(type: :pattern, domain: :cognitive,
                            content: 'x', depth_level: :bogus)
      end.to raise_error(ArgumentError, /unknown depth level/)
    end
  end

  describe '#preservation' do
    it 'aliases preservation_quality' do
      expect(artifact.preservation).to eq artifact.preservation_quality
    end
  end

  describe '#decay!' do
    it 'reduces preservation_quality' do
      original = artifact.preservation_quality
      artifact.decay!
      expect(artifact.preservation_quality).to be < original
    end

    it 'reduces integrity' do
      original = artifact.integrity
      artifact.decay!
      expect(artifact.integrity).to be < original
    end

    it 'clamps preservation at 0.0' do
      30.times { artifact.decay!(rate: 0.1) }
      expect(artifact.preservation_quality).to eq 0.0
    end

    it 'returns self for chaining' do
      expect(artifact.decay!).to eq artifact
    end
  end

  describe '#restore!' do
    before { artifact.decay!(rate: 0.2) }

    it 'increases preservation_quality' do
      original = artifact.preservation_quality
      artifact.restore!(boost: 0.1)
      expect(artifact.preservation_quality).to be > original
    end

    it 'clamps preservation at 1.0' do
      artifact.restore!(boost: 5.0)
      expect(artifact.preservation_quality).to eq 1.0
    end

    it 'returns self for chaining' do
      expect(artifact.restore!).to eq artifact
    end
  end

  describe '#fragment?' do
    it 'returns true when preservation < 0.3' do
      artifact.instance_variable_set(:@preservation_quality, 0.2)
      expect(artifact.fragment?).to be true
    end

    it 'returns false when preservation >= 0.3' do
      expect(artifact.fragment?).to be false
    end
  end

  describe '#well_preserved?' do
    it 'returns true when preservation > 0.7' do
      artifact.instance_variable_set(:@preservation_quality, 0.8)
      expect(artifact.well_preserved?).to be true
    end

    it 'returns false when preservation <= 0.7' do
      expect(artifact.well_preserved?).to be false
    end
  end

  describe '#preservation_label' do
    it 'returns label based on preservation' do
      artifact.instance_variable_set(:@preservation_quality, 0.1)
      expect(artifact.preservation_label).to eq :dust

      artifact.instance_variable_set(:@preservation_quality, 0.9)
      expect(artifact.preservation_label).to eq :pristine
    end
  end

  describe '#integrity_label' do
    it 'returns label based on integrity' do
      artifact.instance_variable_set(:@integrity, 0.1)
      expect(artifact.integrity_label).to eq :corrupted

      artifact.instance_variable_set(:@integrity, 0.9)
      expect(artifact.integrity_label).to eq :complete
    end
  end

  describe '#link_to' do
    it 'adds a contextual link' do
      artifact.link_to('other-id')
      expect(artifact.contextual_links).to include('other-id')
    end

    it 'does not duplicate links' do
      artifact.link_to('same-id')
      artifact.link_to('same-id')
      expect(artifact.contextual_links.count('same-id')).to eq 1
    end
  end

  describe '#to_h' do
    subject(:hash) { artifact.to_h }

    it 'includes all fields' do
      %i[id artifact_type domain content depth_level preservation_quality
         preservation_label integrity integrity_label discovered_at
         origin_epoch contextual_links fragment well_preserved ancient].each do |key|
        expect(hash).to have_key(key)
      end
    end
  end
end
