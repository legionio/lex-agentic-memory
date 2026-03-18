# frozen_string_literal: true

require 'legion/extensions/agentic/memory/source_monitoring/client'

RSpec.describe Legion::Extensions::Agentic::Memory::SourceMonitoring::Client do
  subject(:client) { described_class.new }

  it 'records and verifies sources' do
    rec = client.record_source(content_id: 'fact:x', source: :external_perception)
    result = client.verify_source(record_id: rec[:record][:id])
    expect(result[:success]).to be true
    expect(result[:record][:verified]).to be true
  end

  it 'performs reality checks' do
    client.record_source(content_id: 'thought:y', source: :internal_generation)
    result = client.reality_check(content_id: 'thought:y')
    expect(result[:status]).to eq(:constructed)
  end

  it 'reports stats' do
    result = client.source_monitoring_stats
    expect(result[:success]).to be true
  end
end
