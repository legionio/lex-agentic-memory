# frozen_string_literal: true

require 'legion/extensions/agentic/memory/trace/client'

RSpec.describe Legion::Extensions::Agentic::Memory::Trace::Client do
  let(:client) { described_class.new }

  it 'responds to trace runner methods' do
    expect(client).to respond_to(:store_trace)
    expect(client).to respond_to(:get_trace)
    expect(client).to respond_to(:retrieve_by_type)
    expect(client).to respond_to(:retrieve_by_domain)
    expect(client).to respond_to(:retrieve_associated)
    expect(client).to respond_to(:retrieve_ranked)
    expect(client).to respond_to(:delete_trace)
  end

  it 'responds to consolidation runner methods' do
    expect(client).to respond_to(:reinforce)
    expect(client).to respond_to(:decay_cycle)
    expect(client).to respond_to(:migrate_tier)
    expect(client).to respond_to(:hebbian_link)
    expect(client).to respond_to(:erase_by_type)
    expect(client).to respond_to(:erase_by_agent)
  end

  it 'does not initialize the shared trace store until a store-backed operation needs it' do
    allow(Legion::Extensions::Agentic::Memory::Trace).to receive(:shared_store)

    described_class.new

    expect(Legion::Extensions::Agentic::Memory::Trace).not_to have_received(:shared_store)
  end

  it 'uses provided store' do
    store = Legion::Extensions::Agentic::Memory::Trace::Helpers::Store.new
    client = described_class.new(store: store)
    client.store_trace(type: :semantic, content_payload: { fact: 'test' })
    expect(store.count).to eq(1)
  end

  it 'round-trips a full trace lifecycle' do
    # Store
    stored = client.store_trace(type: :procedural, content_payload: { action: 'greet' }, domain_tags: ['social'])

    # Retrieve
    trace = client.get_trace(trace_id: stored[:trace_id])
    expect(trace[:found]).to be true
    expect(trace[:trace][:strength]).to eq(0.4)

    # Reinforce
    client.reinforce(trace_id: stored[:trace_id])
    trace = client.get_trace(trace_id: stored[:trace_id])
    expect(trace[:trace][:strength]).to eq(0.5)

    # Reinforce again
    client.reinforce(trace_id: stored[:trace_id])
    trace = client.get_trace(trace_id: stored[:trace_id])
    expect(trace[:trace][:strength]).to eq(0.6)

    # Query by domain
    by_domain = client.retrieve_by_domain(domain_tag: 'social')
    expect(by_domain[:count]).to eq(1)

    # Delete
    client.delete_trace(trace_id: stored[:trace_id])
    trace = client.get_trace(trace_id: stored[:trace_id])
    expect(trace[:found]).to be false
  end
end
