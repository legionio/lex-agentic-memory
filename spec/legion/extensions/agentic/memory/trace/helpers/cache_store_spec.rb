# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Trace::Helpers::CacheStore do
  describe '#initialize' do
    it 'has logging and cache helpers when loaded directly' do
      allow(Legion::Cache).to receive(:get).and_return(nil)

      store = described_class.new

      expect(store).to respond_to(:log)
      expect(store).to respond_to(:cache_get)
    end
  end

  describe '#flush' do
    it 'passes cache TTL as a keyword argument' do
      allow(Legion::Cache).to receive(:get).and_return(nil)
      allow(Legion::Cache).to receive(:set).and_return(true)
      store = described_class.new
      trace = Legion::Extensions::Agentic::Memory::Trace::Helpers::Trace.new_trace(
        type:            :semantic,
        content_payload: { fact: 'cache flush' }
      )

      store.store(trace)
      store.flush

      expect(Legion::Cache).to have_received(:set).with(
        a_string_including(trace[:trace_id]),
        trace,
        ttl:   described_class::TTL,
        async: false,
        phi:   false
      )
    end
  end
end
