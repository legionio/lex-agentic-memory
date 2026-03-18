# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Paleontology::Runners::CognitivePaleontology do
  let(:engine) { Legion::Extensions::Agentic::Memory::Paleontology::Helpers::PaleontologyEngine.new }
  let(:runner) { described_class }

  describe '.record_extinction' do
    it 'succeeds' do
      result = runner.record_extinction(
        fossil_type: :strategy, domain: :cognitive, content: 'old way',
        extinction_cause: :obsolescence, engine: engine
      )
      expect(result[:success]).to be true
      expect(result[:fossil][:fossil_type]).to eq :strategy
    end

    it 'returns failure for invalid type' do
      result = runner.record_extinction(
        fossil_type: :bogus, domain: :cognitive, content: 'x',
        extinction_cause: :obsolescence, engine: engine
      )
      expect(result[:success]).to be false
    end
  end

  describe '.begin_excavation' do
    it 'succeeds' do
      result = runner.begin_excavation(target_stratum: 1, engine: engine)
      expect(result[:success]).to be true
      expect(result[:excavation][:target_stratum]).to eq 1
    end
  end

  describe '.excavate' do
    it 'returns fossil when found' do
      engine.record_extinction(
        fossil_type: :pattern, domain: :semantic, content: 'x',
        extinction_cause: :displacement, stratum_depth: 1
      )
      exc = engine.begin_excavation(target_stratum: 1)
      result = runner.excavate(excavation_id: exc.id, engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns nil message when empty stratum' do
      exc = engine.begin_excavation(target_stratum: 4)
      result = runner.excavate(excavation_id: exc.id, engine: engine)
      expect(result[:success]).to be true
      expect(result[:fossil]).to be_nil
    end
  end

  describe '.list_fossils' do
    before do
      engine.record_extinction(
        fossil_type: :strategy, domain: :cognitive, content: 'a',
        extinction_cause: :obsolescence
      )
      engine.record_extinction(
        fossil_type: :pattern, domain: :semantic, content: 'b',
        extinction_cause: :displacement
      )
    end

    it 'lists all' do
      result = runner.list_fossils(engine: engine)
      expect(result[:count]).to eq 2
    end

    it 'filters by type' do
      result = runner.list_fossils(engine: engine, fossil_type: :strategy)
      expect(result[:count]).to eq 1
    end

    it 'filters by cause' do
      result = runner.list_fossils(engine:           engine,
                                   extinction_cause: :displacement)
      expect(result[:count]).to eq 1
    end
  end

  describe '.paleontology_status' do
    it 'returns report' do
      result = runner.paleontology_status(engine: engine)
      expect(result[:success]).to be true
      expect(result[:report]).to be_a Hash
    end
  end
end
