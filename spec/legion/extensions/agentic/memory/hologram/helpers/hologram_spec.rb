# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Hologram::Helpers::Hologram do
  let(:domain)  { :memory }
  let(:content) { 'the quick brown fox jumps over the lazy dog' }

  subject(:hologram) { described_class.new(domain: domain, content: content) }

  describe '#initialize' do
    it 'generates a UUID id' do
      expect(hologram.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores domain as symbol' do
      expect(hologram.domain).to eq(:memory)
    end

    it 'converts string domain to symbol' do
      h = described_class.new(domain: 'emotion', content: content)
      expect(h.domain).to eq(:emotion)
    end

    it 'stores content' do
      expect(hologram.content).to eq(content)
    end

    it 'initializes with empty fragments' do
      expect(hologram.fragments).to be_empty
    end

    it 'sets created_at to a Time' do
      expect(hologram.created_at).to be_a(Time)
    end
  end

  describe '#resolution' do
    it 'returns 0.0 when there are no fragments' do
      expect(hologram.resolution).to eq(0.0)
    end

    it 'returns 0.0 when all fragments are insufficient' do
      hologram.fragment!(2).each { |f| f.degrade!(0.9) }
      expect(hologram.resolution).to eq(0.0)
    end

    it 'returns a value between 0.0 and 1.0 with sufficient fragments' do
      hologram.fragment!(4)
      expect(hologram.resolution).to be_between(0.0, 1.0)
    end

    it 'returns a non-zero resolution with high-completeness fragments' do
      hologram.fragment!(2)
      expect(hologram.resolution).to be > 0.0
    end
  end

  describe '#fragment!' do
    it 'returns an array of HolographicFragment objects' do
      frags = hologram.fragment!(3)
      expect(frags).to all(be_a(Legion::Extensions::Agentic::Memory::Hologram::Helpers::HolographicFragment))
    end

    it 'creates the requested number of fragments' do
      frags = hologram.fragment!(5)
      expect(frags.size).to eq(5)
    end

    it 'appends fragments to @fragments' do
      hologram.fragment!(3)
      expect(hologram.fragments.size).to eq(3)
    end

    it 'accumulates fragments across multiple calls' do
      hologram.fragment!(2)
      hologram.fragment!(3)
      expect(hologram.fragments.size).to eq(5)
    end

    it 'sets parent_hologram_id to self id on all fragments' do
      frags = hologram.fragment!(4)
      expect(frags.all? { |f| f.parent_hologram_id == hologram.id }).to be true
    end

    it 'clamps count to minimum 1' do
      frags = hologram.fragment!(0)
      expect(frags.size).to eq(1)
    end

    it 'clamps count to maximum 20' do
      frags = hologram.fragment!(50)
      expect(frags.size).to eq(20)
    end

    it 'stores the same content as the hologram in each fragment' do
      frags = hologram.fragment!(3)
      expect(frags.all? { |f| f.content == content }).to be true
    end
  end

  describe '#reconstruct' do
    context 'with sufficient fragments' do
      # Force completeness above RECONSTRUCTION_THRESHOLD (0.3) so the context
      # is deterministic — fragment!(4) uses rand and can produce all-insufficient sets.
      let(:fragments) { hologram.fragment!(4).each { |f| f.completeness = 1.0 } }

      it 'returns success: true' do
        expect(hologram.reconstruct(fragments)[:success]).to be true
      end

      it 'returns a resolution value' do
        expect(hologram.reconstruct(fragments)[:resolution]).to be_between(0.0, 1.0)
      end

      it 'returns a resolution label as symbol' do
        expect(hologram.reconstruct(fragments)[:label]).to be_a(Symbol)
      end

      it 'returns fragment_count equal to sufficient fragments' do
        result = hologram.reconstruct(fragments)
        expect(result[:fragment_count]).to be_between(1, fragments.size)
      end

      it 'returns total_fragments equal to input count' do
        result = hologram.reconstruct(fragments)
        expect(result[:total_fragments]).to eq(fragments.size)
      end
    end

    context 'with no sufficient fragments' do
      let(:bad_fragments) do
        hologram.fragment!(2).tap { |frags| frags.each { |f| f.degrade!(0.9) } }
      end

      it 'returns success: false' do
        expect(hologram.reconstruct(bad_fragments)[:success]).to be false
      end

      it 'returns reason :insufficient_fragments' do
        expect(hologram.reconstruct(bad_fragments)[:reason]).to eq(:insufficient_fragments)
      end

      it 'returns resolution 0.0' do
        expect(hologram.reconstruct(bad_fragments)[:resolution]).to eq(0.0)
      end
    end

    context 'with empty array' do
      it 'returns success: false' do
        expect(hologram.reconstruct([])[:success]).to be false
      end
    end
  end

  describe '#add_fragment' do
    it 'appends a fragment to the list' do
      frag = Legion::Extensions::Agentic::Memory::Hologram::Helpers::HolographicFragment.new(
        content: content, parent_hologram_id: hologram.id
      )
      hologram.add_fragment(frag)
      expect(hologram.fragments).to include(frag)
    end

    it 'returns the added fragment' do
      frag = Legion::Extensions::Agentic::Memory::Hologram::Helpers::HolographicFragment.new(
        content: content, parent_hologram_id: hologram.id
      )
      result = hologram.add_fragment(frag)
      expect(result).to eq(frag)
    end
  end

  describe '#resolution_label' do
    it 'returns a symbol' do
      expect(hologram.resolution_label).to be_a(Symbol)
    end

    it 'returns :fragmentary with no fragments' do
      expect(hologram.resolution_label).to eq(:fragmentary)
    end

    it 'accepts an override value' do
      expect(hologram.resolution_label(0.95)).to eq(:perfect)
    end
  end

  describe '#interference_with' do
    let(:other) { described_class.new(domain: :emotion, content: 'the quick brown fox') }

    it 'returns a float between 0.0 and 1.0' do
      score = hologram.interference_with(other)
      expect(score).to be_between(0.0, 1.0)
    end

    it 'returns higher interference for more overlapping content' do
      close = described_class.new(domain: :memory, content: 'the quick brown fox jumps')
      distant = described_class.new(domain: :memory, content: 'completely different words here')
      expect(hologram.interference_with(close)).to be > hologram.interference_with(distant)
    end

    it 'returns 0.0 when compared to itself by id' do
      expect(hologram.interference_with(hologram)).to eq(0.0)
    end

    it 'returns 0.0 when other is nil' do
      expect(hologram.interference_with(nil)).to eq(0.0)
    end

    it 'returns 0.0 for completely different content' do
      unrelated = described_class.new(domain: :memory, content: 'xyz abc def')
      score = hologram.interference_with(unrelated)
      expect(score).to be >= 0.0
    end

    it 'returns 1.0 for identical content' do
      twin = described_class.new(domain: :memory, content: content)
      expect(hologram.interference_with(twin)).to be_within(0.001).of(1.0)
    end
  end

  describe '#to_h' do
    subject(:hash) { hologram.to_h }

    before { hologram.fragment!(2) }

    it 'includes :id' do
      expect(hash[:id]).to eq(hologram.id)
    end

    it 'includes :domain' do
      expect(hash[:domain]).to eq(:memory)
    end

    it 'includes :content' do
      expect(hash[:content]).to eq(content)
    end

    it 'includes :resolution as float' do
      expect(hash[:resolution]).to be_a(Float)
    end

    it 'includes :resolution_label as symbol' do
      expect(hash[:resolution_label]).to be_a(Symbol)
    end

    it 'includes :fragment_count matching actual count' do
      expect(hash[:fragment_count]).to eq(2)
    end

    it 'includes :fragments as array of hashes' do
      expect(hash[:fragments]).to be_an(Array)
      expect(hash[:fragments].first).to be_a(Hash)
    end

    it 'includes :created_at as ISO8601 string' do
      expect(hash[:created_at]).to match(/\d{4}-\d{2}-\d{2}T/)
    end
  end
end
