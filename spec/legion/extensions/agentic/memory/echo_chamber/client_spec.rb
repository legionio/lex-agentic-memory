# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::EchoChamber::Client do
  subject(:client) { described_class.new }

  describe '#initialize' do
    it 'creates a client with a default engine' do
      expect(client).to respond_to(:create_echo)
    end

    it 'accepts an injected engine' do
      engine = Legion::Extensions::Agentic::Memory::EchoChamber::Helpers::ChamberEngine.new
      custom = described_class.new(engine: engine)
      expect(custom).to respond_to(:chamber_status)
    end
  end

  describe 'runner method delegation' do
    it 'responds to create_echo' do
      expect(client).to respond_to(:create_echo)
    end

    it 'responds to create_chamber' do
      expect(client).to respond_to(:create_chamber)
    end

    it 'responds to amplify' do
      expect(client).to respond_to(:amplify)
    end

    it 'responds to disrupt' do
      expect(client).to respond_to(:disrupt)
    end

    it 'responds to list_echoes' do
      expect(client).to respond_to(:list_echoes)
    end

    it 'responds to chamber_status' do
      expect(client).to respond_to(:chamber_status)
    end
  end

  describe 'full echo lifecycle' do
    it 'creates, amplifies, and lists echoes' do
      result = client.create_echo(content: 'confirmation bias', domain: :cognition, echo_type: :bias)
      expect(result[:success]).to be true
      echo_id = result[:echo][:id]

      amplify_result = client.amplify(echo_id: echo_id)
      expect(amplify_result[:success]).to be true
      expect(amplify_result[:echo][:amplitude]).to be > 0.5

      list_result = client.list_echoes(echo_type: :bias)
      expect(list_result[:count]).to eq(1)
    end

    it 'creates a chamber and disrupts it' do
      chamber_result = client.create_chamber(label: 'echo chamber', wall_thickness: 0.4)
      expect(chamber_result[:success]).to be true
      chamber_id = chamber_result[:chamber][:id]

      disrupt_result = client.disrupt(chamber_id: chamber_id, force: 0.9)
      expect(disrupt_result[:success]).to be true
    end

    it 'reports status with echoes and chambers' do
      client.create_echo(content: 'belief 1')
      client.create_chamber(label: 'chamber 1')

      status = client.chamber_status
      expect(status[:total_echoes]).to eq(1)
      expect(status[:total_chambers]).to eq(1)
    end

    it 'handles disruption failure gracefully' do
      chamber_result = client.create_chamber(label: 'fortified', wall_thickness: 0.9)
      chamber_id     = chamber_result[:chamber][:id]

      result = client.disrupt(chamber_id: chamber_id, force: 0.1)
      expect(result[:success]).to be false
    end
  end
end
