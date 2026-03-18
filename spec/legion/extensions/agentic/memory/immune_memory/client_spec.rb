# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::ImmuneMemory::Client do
  subject(:client) { described_class.new }

  it 'responds to runner methods' do
    expect(client).to respond_to(:create_memory_cell, :vaccinate, :encounter_threat, :immune_status)
  end

  it 'runs a full immune lifecycle' do
    client.vaccinate(threat_type: :prompt_injection, signature: 'known-threat')
    result = client.encounter_threat(threat_type: :prompt_injection, threat_signature: 'known-threat')
    expect(result[:encounter][:response_type]).to eq(:secondary)

    status = client.immune_status
    expect(status[:total_cells]).to be >= 1
  end
end
