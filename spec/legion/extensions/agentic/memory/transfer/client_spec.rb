# frozen_string_literal: true

require 'legion/extensions/agentic/memory/transfer/client'

RSpec.describe Legion::Extensions::Agentic::Memory::Transfer::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:learn_domain)
    expect(client).to respond_to(:attempt_transfer)
    expect(client).to respond_to(:set_similarity)
    expect(client).to respond_to(:transfer_effectiveness)
    expect(client).to respond_to(:most_transferable)
    expect(client).to respond_to(:interference_risks)
    expect(client).to respond_to(:transfer_report)
    expect(client).to respond_to(:get_domain)
  end
end
