# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Episodic::Runners::EpisodicBuffer do
  let(:store) { Legion::Extensions::Agentic::Memory::Episodic::Helpers::EpisodicStore.new }

  let(:runner) do
    obj = Object.new
    obj.extend(described_module)
    obj.instance_variable_set(:@default_store, store)
    obj
  end

  let(:described_module) { described_class }

  subject(:runner_instance) { runner }

  describe '#create_episode' do
    it 'returns success true' do
      result = runner_instance.create_episode
      expect(result[:success]).to be true
    end

    it 'returns an episode_id' do
      result = runner_instance.create_episode
      expect(result[:episode_id]).not_to be_nil
    end

    it 'returns created_at' do
      result = runner_instance.create_episode
      expect(result[:created_at]).to be_a(Time)
    end
  end

  describe '#add_binding' do
    let(:episode_id) { runner_instance.create_episode[:episode_id] }

    it 'returns success true for valid binding' do
      result = runner_instance.add_binding(
        episode_id: episode_id, modality: :verbal, content: 'hello', source: :phonological_loop
      )
      expect(result[:success]).to be true
    end

    it 'returns a binding_id' do
      result = runner_instance.add_binding(
        episode_id: episode_id, modality: :visual, content: 'image', source: :visuospatial
      )
      expect(result[:binding_id]).not_to be_nil
    end

    it 'returns success false for nonexistent episode' do
      result = runner_instance.add_binding(
        episode_id: 'missing', modality: :verbal, content: 'x', source: :test
      )
      expect(result[:success]).to be false
    end

    it 'raises ArgumentError for invalid modality' do
      expect do
        runner_instance.add_binding(episode_id: episode_id, modality: :invalid, content: 'x', source: :test)
      end.to raise_error(ArgumentError, /invalid modality/)
    end
  end

  describe '#attend_episode' do
    let(:episode_id) { runner_instance.create_episode[:episode_id] }

    it 'returns success true for existing episode' do
      result = runner_instance.attend_episode(episode_id: episode_id)
      expect(result[:success]).to be true
    end

    it 'returns success false for missing episode' do
      result = runner_instance.attend_episode(episode_id: 'missing')
      expect(result[:success]).to be false
    end
  end

  describe '#rehearse_episode' do
    let(:episode_id) { runner_instance.create_episode[:episode_id] }

    it 'returns success true for existing episode' do
      result = runner_instance.rehearse_episode(episode_id: episode_id)
      expect(result[:success]).to be true
    end

    it 'returns success false for missing episode' do
      result = runner_instance.rehearse_episode(episode_id: 'missing')
      expect(result[:success]).to be false
    end
  end

  describe '#check_integration' do
    let(:episode_id) { runner_instance.create_episode[:episode_id] }

    it 'returns success true always' do
      result = runner_instance.check_integration(episode_id: episode_id)
      expect(result[:success]).to be true
    end

    it 'includes integrated boolean' do
      result = runner_instance.check_integration(episode_id: episode_id)
      expect(result).to have_key(:integrated)
    end

    it 'reports not integrated for empty episode' do
      result = runner_instance.check_integration(episode_id: episode_id)
      expect(result[:integrated]).to be false
    end

    it 'reports integrated for high-strength bindings' do
      runner_instance.add_binding(episode_id: episode_id, modality: :verbal, content: 'a', source: :test, strength: 0.9)
      runner_instance.add_binding(episode_id: episode_id, modality: :visual, content: 'b', source: :test, strength: 0.9)
      result = runner_instance.check_integration(episode_id: episode_id)
      expect(result[:integrated]).to be true
    end
  end

  describe '#retrieve_by_modality' do
    before do
      id = runner_instance.create_episode[:episode_id]
      runner_instance.add_binding(episode_id: id, modality: :verbal, content: 'word', source: :test)
    end

    it 'returns success true' do
      result = runner_instance.retrieve_by_modality(modality: :verbal)
      expect(result[:success]).to be true
    end

    it 'returns matching episodes' do
      result = runner_instance.retrieve_by_modality(modality: :verbal)
      expect(result[:count]).to eq(1)
    end

    it 'returns empty for non-matching modality' do
      result = runner_instance.retrieve_by_modality(modality: :temporal)
      expect(result[:count]).to eq(0)
    end
  end

  describe '#retrieve_multimodal' do
    it 'returns success true' do
      result = runner_instance.retrieve_multimodal
      expect(result[:success]).to be true
    end

    it 'returns only multimodal episodes' do
      id = runner_instance.create_episode[:episode_id]
      runner_instance.add_binding(episode_id: id, modality: :verbal, content: 'a', source: :test)
      runner_instance.add_binding(episode_id: id, modality: :visual, content: 'b', source: :test)

      unimodal_id = runner_instance.create_episode[:episode_id]
      runner_instance.add_binding(episode_id: unimodal_id, modality: :verbal, content: 'c', source: :test)

      result = runner_instance.retrieve_multimodal
      expect(result[:count]).to eq(1)
    end
  end

  describe '#most_coherent' do
    it 'returns success true' do
      result = runner_instance.most_coherent
      expect(result[:success]).to be true
    end

    it 'returns up to limit episodes' do
      3.times { runner_instance.create_episode }
      result = runner_instance.most_coherent(limit: 2)
      expect(result[:count]).to be <= 2
    end

    it 'defaults limit to 5' do
      result = runner_instance.most_coherent
      expect(result[:count]).to be <= 5
    end
  end

  describe '#update_episodic_buffer' do
    it 'returns success true' do
      result = runner_instance.update_episodic_buffer
      expect(result[:success]).to be true
    end

    it 'returns decayed and expired counts' do
      runner_instance.create_episode
      result = runner_instance.update_episodic_buffer
      expect(result).to include(:decayed, :expired)
    end
  end

  describe '#episodic_buffer_stats' do
    it 'returns success true' do
      result = runner_instance.episodic_buffer_stats
      expect(result[:success]).to be true
    end

    it 'includes episode_count' do
      result = runner_instance.episodic_buffer_stats
      expect(result).to have_key(:episode_count)
    end

    it 'reflects current state' do
      runner_instance.create_episode
      result = runner_instance.episodic_buffer_stats
      expect(result[:episode_count]).to eq(1)
    end
  end
end
