# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Archaeology::Client do
  let(:client) { described_class.new }

  it 'creates with default engine' do
    expect(client).to respond_to(:create_site)
  end

  describe '#create_site' do
    it 'delegates to runner' do
      result = client.create_site(domain: :cognitive)
      expect(result[:success]).to be true
    end
  end

  describe '#excavate' do
    it 'delegates to runner' do
      site_result = client.create_site(domain: :cognitive)
      result = client.excavate(site_id: site_result[:site][:id])
      expect(result[:success]).to be true
    end
  end

  describe '#list_artifacts' do
    it 'returns empty list' do
      result = client.list_artifacts
      expect(result[:count]).to eq 0
    end
  end

  describe '#archaeology_status' do
    it 'returns report' do
      result = client.archaeology_status
      expect(result[:report]).to be_a Hash
    end
  end
end
