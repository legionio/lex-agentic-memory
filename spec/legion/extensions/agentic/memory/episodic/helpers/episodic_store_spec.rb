# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Episodic::Helpers::EpisodicStore do
  let(:store) { described_class.new }

  def add_multimodal_episode(the_store)
    ep = the_store.create_episode
    the_store.add_to_episode(episode_id: ep.id, modality: :verbal, content: 'a', source: :test)
    the_store.add_to_episode(episode_id: ep.id, modality: :visual, content: 'b', source: :test)
    ep
  end

  describe '#initialize' do
    it 'starts with empty episodes' do
      expect(store.episodes).to be_empty
    end

    it 'starts with empty history' do
      expect(store.history).to be_empty
    end
  end

  describe '#create_episode' do
    it 'returns an Episode' do
      ep = store.create_episode
      expect(ep).to be_a(Legion::Extensions::Agentic::Memory::Episodic::Helpers::Episode)
    end

    it 'stores the episode' do
      ep = store.create_episode
      expect(store.episodes).to have_key(ep.id)
    end

    it 'records history' do
      store.create_episode
      expect(store.history.last[:event]).to eq(:create)
    end

    it 'evicts oldest expired episode when at capacity' do
      stub_const('Legion::Extensions::Agentic::Memory::Episodic::Helpers::Constants::MAX_EPISODES', 2)
      e1 = store.create_episode
      e2 = store.create_episode
      expect(store.count).to eq(2)
      allow(e1).to receive(:expired?).and_return(true)
      allow(e2).to receive(:expired?).and_return(false)
      store.create_episode
      expect(store.count).to eq(2)
    end
  end

  describe '#add_to_episode' do
    let(:ep) { store.create_episode }

    it 'adds binding to existing episode' do
      result = store.add_to_episode(
        episode_id: ep.id, modality: :verbal, content: 'hello', source: :phonological_loop
      )
      expect(result[:added]).to be true
    end

    it 'returns failure for missing episode' do
      result = store.add_to_episode(
        episode_id: 'nonexistent', modality: :verbal, content: 'x', source: :test
      )
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:episode_not_found)
    end
  end

  describe '#attend_episode' do
    it 'returns success for existing episode' do
      ep = store.create_episode
      result = store.attend_episode(episode_id: ep.id)
      expect(result[:success]).to be true
    end

    it 'returns failure for missing episode' do
      result = store.attend_episode(episode_id: 'missing')
      expect(result[:success]).to be false
    end
  end

  describe '#rehearse_episode' do
    it 'returns success for existing episode' do
      ep = store.create_episode
      result = store.rehearse_episode(episode_id: ep.id)
      expect(result[:success]).to be true
    end

    it 'returns failure for missing episode' do
      result = store.rehearse_episode(episode_id: 'missing')
      expect(result[:success]).to be false
    end
  end

  describe '#integrate' do
    let(:ep) { store.create_episode }

    it 'returns integrated: false for low-coherence episode' do
      store.add_to_episode(episode_id: ep.id, modality: :verbal, content: 'x', source: :test, strength: 0.1)
      result = store.integrate(episode_id: ep.id)
      expect(result[:integrated]).to be false
    end

    it 'returns integrated: true for high-coherence episode' do
      store.add_to_episode(episode_id: ep.id, modality: :verbal, content: 'a', source: :test, strength: 0.9)
      store.add_to_episode(episode_id: ep.id, modality: :visual, content: 'b', source: :test, strength: 0.9)
      result = store.integrate(episode_id: ep.id)
      expect(result[:integrated]).to be true
    end

    it 'returns failure for missing episode' do
      result = store.integrate(episode_id: 'missing')
      expect(result[:integrated]).to be false
      expect(result[:reason]).to eq(:episode_not_found)
    end

    it 'includes coherence label' do
      store.add_to_episode(episode_id: ep.id, modality: :verbal, content: 'a', source: :test, strength: 0.9)
      result = store.integrate(episode_id: ep.id)
      expect(result[:coherence_label]).not_to be_nil
    end
  end

  describe '#retrieve_by_modality' do
    it 'returns episodes containing that modality' do
      add_multimodal_episode(store)
      results = store.retrieve_by_modality(modality: :verbal)
      expect(results.size).to eq(1)
    end

    it 'returns empty array when no match' do
      expect(store.retrieve_by_modality(modality: :temporal)).to be_empty
    end
  end

  describe '#retrieve_multimodal' do
    it 'returns episodes with 2+ modalities' do
      add_multimodal_episode(store)
      expect(store.retrieve_multimodal.size).to eq(1)
    end

    it 'excludes single-modality episodes' do
      ep = store.create_episode
      store.add_to_episode(episode_id: ep.id, modality: :verbal, content: 'x', source: :test)
      expect(store.retrieve_multimodal).to be_empty
    end
  end

  describe '#most_coherent' do
    it 'returns episodes sorted by coherence descending' do
      ep1 = store.create_episode
      store.add_to_episode(episode_id: ep1.id, modality: :verbal, content: 'a', source: :test, strength: 0.9)
      ep2 = store.create_episode
      store.add_to_episode(episode_id: ep2.id, modality: :visual, content: 'b', source: :test, strength: 0.5)

      results = store.most_coherent(limit: 2)
      expect(results.first.id).to eq(ep1.id)
    end

    it 'respects limit' do
      3.times { store.create_episode }
      expect(store.most_coherent(limit: 2).size).to be <= 2
    end
  end

  describe '#tick' do
    it 'returns a hash with decayed and expired counts' do
      store.create_episode
      result = store.tick
      expect(result).to include(:decayed, :expired)
    end

    it 'removes episodes with faded bindings that are also expired' do
      ep = store.create_episode
      allow(store.episodes[ep.id]).to receive(:expired?).and_return(true)
      store.tick
      expect(store.episodes).not_to have_key(ep.id)
    end
  end

  describe '#count' do
    it 'returns current episode count' do
      store.create_episode
      store.create_episode
      expect(store.count).to eq(2)
    end
  end

  describe '#to_h' do
    it 'returns stats hash' do
      h = store.to_h
      expect(h).to include(:episode_count, :history_size, :multimodal_count, :avg_coherence)
    end

    it 'reflects current episode count' do
      store.create_episode
      expect(store.to_h[:episode_count]).to eq(1)
    end
  end
end
