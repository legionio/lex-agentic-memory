# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Paleontology::Client do
  let(:client) { described_class.new }

  it 'responds to runner methods' do
    expect(client).to respond_to(:record_extinction, :begin_excavation,
                                 :list_fossils, :paleontology_status)
  end

  describe '#record_extinction' do
    it 'delegates' do
      result = client.record_extinction(
        fossil_type: :strategy, domain: :cognitive, content: 'old',
        extinction_cause: :obsolescence
      )
      expect(result[:success]).to be true
    end
  end

  describe '#paleontology_status' do
    it 'returns report' do
      result = client.paleontology_status
      expect(result[:report]).to be_a Hash
    end
  end
end
