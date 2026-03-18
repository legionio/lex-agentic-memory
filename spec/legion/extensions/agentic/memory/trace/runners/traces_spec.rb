# frozen_string_literal: true

require 'legion/extensions/agentic/memory/trace/client'

RSpec.describe Legion::Extensions::Agentic::Memory::Trace::Runners::Traces do
  before(:each) { Legion::Extensions::Agentic::Memory::Trace.reset_store! }

  let(:client) { Legion::Extensions::Agentic::Memory::Trace::Client.new }

  describe '#store_trace' do
    it 'stores a semantic trace and returns id' do
      result = client.store_trace(type: :semantic, content_payload: { fact: 'test' })
      expect(result[:trace_id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:trace_type]).to eq(:semantic)
      expect(result[:strength]).to eq(0.5)
    end

    it 'stores all 7 trace types' do
      Legion::Extensions::Agentic::Memory::Trace::Helpers::Trace::TRACE_TYPES.each do |type|
        result = client.store_trace(type: type, content_payload: {})
        expect(result[:trace_type]).to eq(type)
      end
    end
  end

  describe '#get_trace' do
    it 'retrieves a stored trace' do
      stored = client.store_trace(type: :episodic, content_payload: { event: 'meeting' })
      result = client.get_trace(trace_id: stored[:trace_id])
      expect(result[:found]).to be true
      expect(result[:trace][:content_payload]).to eq({ event: 'meeting' })
    end

    it 'returns found: false for missing traces' do
      result = client.get_trace(trace_id: 'nonexistent')
      expect(result[:found]).to be false
    end
  end

  describe '#retrieve_by_type' do
    it 'returns traces of specified type' do
      client.store_trace(type: :semantic, content_payload: { fact: 'a' })
      client.store_trace(type: :semantic, content_payload: { fact: 'b' })
      client.store_trace(type: :episodic, content_payload: { event: 'c' })

      result = client.retrieve_by_type(type: :semantic)
      expect(result[:count]).to eq(2)
    end
  end

  describe '#retrieve_by_domain' do
    it 'returns traces matching domain tag' do
      client.store_trace(type: :semantic, content_payload: {}, domain_tags: ['work'])
      client.store_trace(type: :semantic, content_payload: {}, domain_tags: ['personal'])

      result = client.retrieve_by_domain(domain_tag: 'work')
      expect(result[:count]).to eq(1)
    end
  end

  describe '#delete_trace' do
    it 'removes a trace' do
      stored = client.store_trace(type: :semantic, content_payload: {})
      client.delete_trace(trace_id: stored[:trace_id])
      result = client.get_trace(trace_id: stored[:trace_id])
      expect(result[:found]).to be false
    end
  end
end
