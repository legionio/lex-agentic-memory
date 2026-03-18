# frozen_string_literal: true

require 'legion/extensions/agentic/memory/semantic_satiation/client'

RSpec.describe Legion::Extensions::Agentic::Memory::SemanticSatiation::Client do
  it 'responds to runner methods' do
    client = described_class.new
    expect(client).to respond_to(:expose)
    expect(client).to respond_to(:register)
    expect(client).to respond_to(:expose_by_id)
    expect(client).to respond_to(:recover)
    expect(client).to respond_to(:satiation_status)
    expect(client).to respond_to(:domain_satiation)
    expect(client).to respond_to(:most_exposed)
    expect(client).to respond_to(:freshest_concepts)
    expect(client).to respond_to(:novelty_report)
    expect(client).to respond_to(:prune_saturated)
  end
end
