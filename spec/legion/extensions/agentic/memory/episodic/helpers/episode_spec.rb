# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Episodic::Helpers::Episode do
  let(:episode) { described_class.new }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(episode.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'starts with empty bindings' do
      expect(episode.bindings).to be_empty
    end

    it 'sets created_at' do
      expect(episode.created_at).to be_a(Time)
    end

    it 'sets last_accessed' do
      expect(episode.last_accessed).to be_a(Time)
    end
  end

  describe '#add_binding' do
    it 'adds a binding successfully' do
      result = episode.add_binding(modality: :verbal, content: 'test', source: :phonological_loop)
      expect(result[:added]).to be true
      expect(result[:binding_id]).not_to be_nil
    end

    it 'stores binding in the bindings hash' do
      result = episode.add_binding(modality: :verbal, content: 'test', source: :phonological_loop)
      expect(episode.bindings).to have_key(result[:binding_id])
    end

    it 'rejects binding when at capacity' do
      10.times { |i| episode.add_binding(modality: :verbal, content: "item #{i}", source: :test) }
      result = episode.add_binding(modality: :visual, content: 'overflow', source: :test)
      expect(result[:added]).to be false
      expect(result[:reason]).to eq(:capacity_full)
    end

    it 'accepts all modalities' do
      %i[verbal visual spatial semantic emotional procedural temporal].each_with_index do |mod, idx|
        result = episode.add_binding(modality: mod, content: "content #{idx}", source: :test)
        expect(result[:added]).to be true
      end
    end
  end

  describe '#remove_binding' do
    it 'removes an existing binding' do
      result = episode.add_binding(modality: :verbal, content: 'test', source: :test)
      remove_result = episode.remove_binding(binding_id: result[:binding_id])
      expect(remove_result[:removed]).to be true
    end

    it 'returns false for unknown binding' do
      result = episode.remove_binding(binding_id: 'nonexistent-id')
      expect(result[:removed]).to be false
    end
  end

  describe '#attend' do
    it 'updates last_accessed' do
      before = episode.last_accessed
      sleep(0.01)
      episode.attend
      expect(episode.last_accessed).to be >= before
    end

    it 'boosts all binding strengths' do
      episode.add_binding(modality: :verbal, content: 'test', source: :test, strength: 0.3)
      initial_strengths = episode.bindings.values.map(&:strength)
      episode.attend
      episode.bindings.values.each_with_index do |b, i|
        expect(b.strength).to be > initial_strengths[i]
      end
    end
  end

  describe '#rehearse' do
    it 'updates last_accessed' do
      before = episode.last_accessed
      sleep(0.01)
      episode.rehearse
      expect(episode.last_accessed).to be >= before
    end

    it 'boosts bindings by REHEARSAL_BOOST' do
      episode.add_binding(modality: :verbal, content: 'test', source: :test, strength: 0.3)
      initial = episode.bindings.values.first.strength
      episode.rehearse
      expect(episode.bindings.values.first.strength).to be_within(0.001).of(initial + 0.15)
    end
  end

  describe '#modalities_present' do
    it 'returns empty array for empty episode' do
      expect(episode.modalities_present).to eq([])
    end

    it 'returns unique modalities' do
      episode.add_binding(modality: :verbal, content: 'a', source: :test)
      episode.add_binding(modality: :visual, content: 'b', source: :test)
      episode.add_binding(modality: :verbal, content: 'c', source: :test)
      expect(episode.modalities_present).to contain_exactly(:verbal, :visual)
    end
  end

  describe '#coherence' do
    it 'returns 0.0 for empty episode' do
      expect(episode.coherence).to eq(0.0)
    end

    it 'returns 0.0 when no bindings are integrated' do
      episode.add_binding(modality: :verbal, content: 'x', source: :test, strength: 0.1)
      expect(episode.coherence).to eq(0.0)
    end

    it 'returns average strength of integrated bindings' do
      episode.add_binding(modality: :verbal, content: 'a', source: :test, strength: 0.6)
      episode.add_binding(modality: :visual, content: 'b', source: :test, strength: 0.8)
      expected = (0.6 + 0.8) / 2.0
      expect(episode.coherence).to be_within(0.001).of(expected)
    end
  end

  describe '#coherence_label' do
    it 'returns :fragmented for low coherence' do
      episode.add_binding(modality: :verbal, content: 'x', source: :test, strength: 0.1)
      expect(episode.coherence_label).to eq(:fragmented)
    end

    it 'returns coherence label for integrated bindings' do
      episode.add_binding(modality: :verbal, content: 'a', source: :test, strength: 0.7)
      episode.add_binding(modality: :visual, content: 'b', source: :test, strength: 0.7)
      expect(episode.coherence_label).to eq(:coherent)
    end
  end

  describe '#multimodal?' do
    it 'returns false for single modality' do
      episode.add_binding(modality: :verbal, content: 'a', source: :test)
      expect(episode.multimodal?).to be false
    end

    it 'returns true for 2+ modalities' do
      episode.add_binding(modality: :verbal, content: 'a', source: :test)
      episode.add_binding(modality: :visual, content: 'b', source: :test)
      expect(episode.multimodal?).to be true
    end
  end

  describe '#expired?' do
    it 'returns false for fresh episode' do
      expect(episode.expired?).to be false
    end
  end

  describe '#decay_bindings' do
    it 'decays all binding strengths' do
      episode.add_binding(modality: :verbal, content: 'a', source: :test, strength: 0.5)
      initial = episode.bindings.values.first.strength
      episode.decay_bindings
      expect(episode.bindings.values.first.strength).to be < initial
    end

    it 'removes faded bindings' do
      episode.add_binding(modality: :verbal, content: 'a', source: :test, strength: 0.04)
      episode.decay_bindings
      expect(episode.bindings).to be_empty
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = episode.to_h
      expect(h.keys).to include(:id, :bindings, :created_at, :last_accessed, :modalities)
      expect(h.keys).to include(:coherence, :coherence_label, :multimodal, :binding_count)
    end

    it 'reflects current binding count' do
      episode.add_binding(modality: :verbal, content: 'a', source: :test)
      expect(episode.to_h[:binding_count]).to eq(1)
    end
  end
end
