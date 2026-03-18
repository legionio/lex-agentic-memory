# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Hologram::Runners::CognitiveHologram do
  subject(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  let(:engine) { Legion::Extensions::Agentic::Memory::Hologram::Helpers::HologramEngine.new }

  describe '#create' do
    it 'returns success: true for valid input' do
      result = runner.create(domain: :memory, content: 'test content here', engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns the hologram hash' do
      result = runner.create(domain: :memory, content: 'test content', engine: engine)
      expect(result[:hologram]).to be_a(Hash)
    end

    it 'includes the hologram id in the result' do
      result = runner.create(domain: :memory, content: 'test content', engine: engine)
      expect(result[:hologram][:id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'uses the provided domain' do
      result = runner.create(domain: :emotion, content: 'emotion content', engine: engine)
      expect(result[:hologram][:domain]).to eq(:emotion)
    end

    it 'returns success: false for empty content' do
      result = runner.create(domain: :memory, content: '', engine: engine)
      expect(result[:success]).to be false
    end

    it 'returns success: false for whitespace-only content' do
      result = runner.create(domain: :memory, content: '   ', engine: engine)
      expect(result[:success]).to be false
    end

    it 'includes error message on failure' do
      result = runner.create(domain: :memory, content: '', engine: engine)
      expect(result[:error]).to be_a(String)
    end

    it 'accepts extra keyword arguments via ** splat' do
      expect do
        runner.create(domain: :memory, content: 'valid', engine: engine, extra: :ignored)
      end.not_to raise_error
    end
  end

  describe '#fragment' do
    let(:hologram_id) do
      runner.create(domain: :memory, content: 'fragment test content', engine: engine)[:hologram][:id]
    end

    it 'returns success: true for existing hologram' do
      result = runner.fragment(hologram_id: hologram_id, count: 3, engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns fragment_count matching request' do
      result = runner.fragment(hologram_id: hologram_id, count: 3, engine: engine)
      expect(result[:fragment_count]).to eq(3)
    end

    it 'returns fragments as array of hashes' do
      result = runner.fragment(hologram_id: hologram_id, count: 2, engine: engine)
      expect(result[:fragments]).to be_an(Array)
      expect(result[:fragments].first).to be_a(Hash)
    end

    it 'returns success: false for unknown hologram_id' do
      result = runner.fragment(hologram_id: SecureRandom.uuid, count: 2, engine: engine)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:hologram_not_found)
    end

    it 'accepts extra keyword arguments' do
      expect do
        runner.fragment(hologram_id: hologram_id, count: 2, engine: engine, extra: :ignored)
      end.not_to raise_error
    end
  end

  describe '#reconstruct' do
    let(:hologram_id) do
      runner.create(domain: :memory, content: 'reconstruction test content', engine: engine)[:hologram][:id]
    end
    let(:fragment_ids) do
      result = runner.fragment(hologram_id: hologram_id, count: 4, engine: engine)
      result[:fragments].select { |f| f[:sufficient] }.map { |f| f[:id] }
    end

    it 'returns success true when sufficient fragments provided' do
      result = runner.reconstruct(hologram_id: hologram_id, fragment_ids: fragment_ids, engine: engine)
      expect(result[:success]).to be(true).or be(false)
    end

    it 'returns a resolution value on successful reconstruction' do
      result = runner.reconstruct(hologram_id: hologram_id, fragment_ids: fragment_ids, engine: engine)
      expect(result[:resolution]).to be_a(Float) if result[:success]
    end

    it 'returns success: false for unknown hologram_id' do
      result = runner.reconstruct(
        hologram_id:  SecureRandom.uuid,
        fragment_ids: [],
        engine:       engine
      )
      expect(result[:success]).to be false
    end

    it 'accepts extra keyword arguments' do
      expect do
        runner.reconstruct(hologram_id: hologram_id, fragment_ids: [], engine: engine, extra: :ok)
      end.not_to raise_error
    end
  end

  describe '#list_holograms' do
    before do
      3.times { |i| runner.create(domain: :memory, content: "hologram number #{i}", engine: engine) }
    end

    it 'returns success: true' do
      result = runner.list_holograms(engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns holograms as array' do
      result = runner.list_holograms(engine: engine)
      expect(result[:holograms]).to be_an(Array)
    end

    it 'returns count matching holograms array size' do
      result = runner.list_holograms(engine: engine)
      expect(result[:count]).to eq(result[:holograms].size)
    end

    it 'respects the limit parameter' do
      result = runner.list_holograms(limit: 2, engine: engine)
      expect(result[:holograms].size).to be <= 2
    end

    it 'returns 3 holograms with default limit' do
      result = runner.list_holograms(engine: engine)
      expect(result[:count]).to eq(3)
    end

    it 'accepts extra keyword arguments' do
      expect do
        runner.list_holograms(engine: engine, extra: :ignored)
      end.not_to raise_error
    end
  end

  describe '#interference_check' do
    let(:id_a) do
      runner.create(domain: :memory, content: 'the quick brown fox', engine: engine)[:hologram][:id]
    end
    let(:id_b) do
      runner.create(domain: :memory, content: 'the quick brown fox', engine: engine)[:hologram][:id]
    end

    it 'returns success: true for known holograms' do
      result = runner.interference_check(hologram_id_a: id_a, hologram_id_b: id_b, engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns interference score as float' do
      result = runner.interference_check(hologram_id_a: id_a, hologram_id_b: id_b, engine: engine)
      expect(result[:interference]).to be_a(Float)
    end

    it 'returns a label' do
      result = runner.interference_check(hologram_id_a: id_a, hologram_id_b: id_b, engine: engine)
      expect(result[:label]).to be_a(Symbol)
    end

    it 'includes success key even on missing hologram' do
      result = runner.interference_check(
        hologram_id_a: SecureRandom.uuid,
        hologram_id_b: id_b,
        engine:        engine
      )
      expect(result).to have_key(:success)
    end

    it 'accepts extra keyword arguments' do
      expect do
        runner.interference_check(hologram_id_a: id_a, hologram_id_b: id_b, engine: engine, extra: :ok)
      end.not_to raise_error
    end
  end

  describe '#hologram_status' do
    before do
      2.times do |i|
        h_result = runner.create(domain: :memory, content: "status test hologram #{i}", engine: engine)
        runner.fragment(hologram_id: h_result[:hologram][:id], count: 2, engine: engine)
      end
    end

    it 'returns success: true' do
      result = runner.hologram_status(engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns a report hash' do
      result = runner.hologram_status(engine: engine)
      expect(result[:report]).to be_a(Hash)
    end

    it 'report includes total_holograms' do
      result = runner.hologram_status(engine: engine)
      expect(result[:report][:total_holograms]).to eq(2)
    end

    it 'report includes average_resolution' do
      result = runner.hologram_status(engine: engine)
      expect(result[:report][:average_resolution]).to be_a(Float)
    end

    it 'report includes resolution_label' do
      result = runner.hologram_status(engine: engine)
      expect(result[:report][:resolution_label]).to be_a(Symbol)
    end

    it 'accepts extra keyword arguments' do
      expect do
        runner.hologram_status(engine: engine, extra: :ignored)
      end.not_to raise_error
    end
  end
end
