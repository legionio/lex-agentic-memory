# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Trace do
  it 'has a version number' do
    expect(Legion::Extensions::Agentic::Memory::Trace::VERSION).not_to be_nil
  end

  it 'has a version that is a string' do
    expect(Legion::Extensions::Agentic::Memory::Trace::VERSION).to be_a(String)
  end

  describe '.shared_store' do
    before { described_class.reset_store! }
    after { described_class.reset_store! }

    it 'prefers the agent-local store when local persistence is available' do
      allow(described_class).to receive(:local_store_available?).and_return(true)
      allow(described_class).to receive(:configured_trace_store).and_return(nil)
      allow(described_class).to receive(:resolve_agent_id).and_return('agent-1')
      allow(described_class::Helpers::Store).to receive(:new).with(partition_id: 'agent-1').and_return(:local_store)

      expect(described_class.shared_store).to eq(:local_store)
    end

    it 'uses the shared Postgres store when trace_store is explicitly shared' do
      allow(described_class).to receive(:local_store_available?).and_return(true)
      allow(described_class).to receive(:configured_trace_store).and_return(:shared)
      allow(described_class).to receive(:postgres_available?).and_return(true)
      allow(described_class).to receive(:resolve_agent_id).and_return('agent-1')
      allow(described_class).to receive(:resolve_tenant_id).and_return('tenant-1')
      allow(described_class::Helpers::PostgresStore).to receive(:new)
        .with(tenant_id: 'tenant-1', agent_id: 'agent-1')
        .and_return(:shared_store)

      expect(described_class.shared_store).to eq(:shared_store)
    end

    it 'falls back from Postgres when user lacks INSERT privilege' do
      allow(described_class).to receive(:local_store_available?).and_return(false)
      allow(described_class).to receive(:configured_trace_store).and_return(nil)
      allow(described_class).to receive(:resolve_agent_id).and_return('agent-1')

      conn = double('connection', adapter_scheme: :postgres)
      allow(conn).to receive(:table_exists?).and_return(true)
      allow(Legion::Data).to receive(:respond_to?).and_call_original
      allow(Legion::Data).to receive(:respond_to?).with(:connection).and_return(true)
      allow(Legion::Data).to receive(:connection).and_return(conn)
      allow(Legion::Data).to receive(:can_write?).with(:memory_traces).and_return(false)

      allow(Legion::Cache).to receive(:respond_to?).with(:connected?).and_return(false)
      allow(described_class::Helpers::Store).to receive(:new).with(partition_id: 'agent-1').and_return(:fallback_store)

      expect(described_class.shared_store).to eq(:fallback_store)
    end
  end
end
