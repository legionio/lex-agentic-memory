# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Echo::Client do
  subject(:client) { described_class.new }

  it 'responds to runner methods' do
    expect(client).to respond_to(:create_echo, :decay_all, :echo_status)
  end

  it 'runs a full echo lifecycle' do
    result = client.create_echo(content: 'security analysis', domain: :security, echo_type: :thought)
    echo_id = result[:echo][:id]

    client.decay_all
    client.reinforce_echo(echo_id: echo_id)

    status = client.echo_status
    expect(status[:total_echoes]).to eq(1)
  end
end
