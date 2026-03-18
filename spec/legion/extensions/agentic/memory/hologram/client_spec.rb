# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Hologram::Client do
  subject(:client) { described_class.new }

  it 'can be instantiated' do
    expect(client).to be_a(described_class)
  end

  it 'includes Runners::CognitiveHologram' do
    expect(client).to respond_to(:create)
    expect(client).to respond_to(:fragment)
    expect(client).to respond_to(:reconstruct)
    expect(client).to respond_to(:list_holograms)
    expect(client).to respond_to(:interference_check)
    expect(client).to respond_to(:hologram_status)
  end

  it 'accepts an injected engine' do
    engine = Legion::Extensions::Agentic::Memory::Hologram::Helpers::HologramEngine.new
    c = described_class.new(engine: engine)
    result = c.create(domain: :memory, content: 'injected engine test')
    expect(result[:success]).to be true
  end

  describe '#create' do
    it 'creates a hologram and returns success' do
      result = client.create(domain: :trust, content: 'client create test content')
      expect(result[:success]).to be true
    end

    it 'returns hologram with uuid id' do
      result = client.create(domain: :trust, content: 'client id test')
      expect(result[:hologram][:id]).to match(/\A[0-9a-f-]{36}\z/)
    end
  end

  describe '#fragment' do
    it 'fragments an existing hologram' do
      create_result = client.create(domain: :memory, content: 'fragment me please')
      hologram_id   = create_result[:hologram][:id]
      result        = client.fragment(hologram_id: hologram_id, count: 3)
      expect(result[:success]).to be true
      expect(result[:fragment_count]).to eq(3)
    end
  end

  describe '#hologram_status' do
    it 'returns a report' do
      client.create(domain: :memory, content: 'status check content')
      result = client.hologram_status
      expect(result[:success]).to be true
      expect(result[:report][:total_holograms]).to eq(1)
    end
  end

  describe '#list_holograms' do
    before do
      2.times { |i| client.create(domain: :memory, content: "list test hologram #{i}") }
    end

    it 'returns all created holograms' do
      result = client.list_holograms
      expect(result[:count]).to eq(2)
    end
  end

  describe '#interference_check' do
    let(:id_a) { client.create(domain: :memory, content: 'shared words here')[:hologram][:id] }
    let(:id_b) { client.create(domain: :memory, content: 'shared words here')[:hologram][:id] }

    it 'returns interference data' do
      result = client.interference_check(hologram_id_a: id_a, hologram_id_b: id_b)
      expect(result[:success]).to be true
      expect(result[:interference]).to be_a(Float)
    end
  end

  describe '#reconstruct' do
    let(:hologram_id) { client.create(domain: :memory, content: 'reconstruct me content')[:hologram][:id] }

    it 'attempts reconstruction and returns a result hash' do
      frag_result = client.fragment(hologram_id: hologram_id, count: 4)
      ids = frag_result[:fragments].select { |f| f[:sufficient] }.map { |f| f[:id] }
      result = client.reconstruct(hologram_id: hologram_id, fragment_ids: ids)
      expect(result).to have_key(:success)
    end
  end
end
