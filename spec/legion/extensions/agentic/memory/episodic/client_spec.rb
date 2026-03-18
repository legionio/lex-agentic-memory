# frozen_string_literal: true

require 'legion/extensions/agentic/memory/episodic/client'

RSpec.describe Legion::Extensions::Agentic::Memory::Episodic::Client do
  let(:client) { described_class.new }

  it 'responds to create_episode' do
    expect(client).to respond_to(:create_episode)
  end

  it 'responds to add_binding' do
    expect(client).to respond_to(:add_binding)
  end

  it 'responds to attend_episode' do
    expect(client).to respond_to(:attend_episode)
  end

  it 'responds to rehearse_episode' do
    expect(client).to respond_to(:rehearse_episode)
  end

  it 'responds to check_integration' do
    expect(client).to respond_to(:check_integration)
  end

  it 'responds to retrieve_by_modality' do
    expect(client).to respond_to(:retrieve_by_modality)
  end

  it 'responds to retrieve_multimodal' do
    expect(client).to respond_to(:retrieve_multimodal)
  end

  it 'responds to most_coherent' do
    expect(client).to respond_to(:most_coherent)
  end

  it 'responds to update_episodic_buffer' do
    expect(client).to respond_to(:update_episodic_buffer)
  end

  it 'responds to episodic_buffer_stats' do
    expect(client).to respond_to(:episodic_buffer_stats)
  end

  it 'uses provided store' do
    store = Legion::Extensions::Agentic::Memory::Episodic::Helpers::EpisodicStore.new
    c = described_class.new(store: store)
    c.create_episode
    expect(store.count).to eq(1)
  end

  it 'round-trips a full episode lifecycle' do
    ep = client.create_episode
    expect(ep[:success]).to be true

    add_result = client.add_binding(
      episode_id: ep[:episode_id], modality: :verbal, content: 'hello', source: :phonological_loop
    )
    expect(add_result[:success]).to be true

    client.add_binding(
      episode_id: ep[:episode_id], modality: :visual, content: 'image', source: :visuospatial, strength: 0.9
    )

    attend_result = client.attend_episode(episode_id: ep[:episode_id])
    expect(attend_result[:success]).to be true

    integration = client.check_integration(episode_id: ep[:episode_id])
    expect(integration[:success]).to be true

    multimodal = client.retrieve_multimodal
    expect(multimodal[:count]).to eq(1)

    stats = client.episodic_buffer_stats
    expect(stats[:episode_count]).to eq(1)
  end
end
