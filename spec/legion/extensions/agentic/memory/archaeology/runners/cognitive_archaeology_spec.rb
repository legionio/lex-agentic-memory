# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Archaeology::Runners::CognitiveArchaeology do
  let(:engine) { Legion::Extensions::Agentic::Memory::Archaeology::Helpers::ArchaeologyEngine.new }
  let(:runner) { described_class }

  describe '.create_site' do
    it 'creates a site successfully' do
      result = runner.create_site(domain: :cognitive, engine: engine)
      expect(result[:success]).to be true
      expect(result[:site][:domain]).to eq :cognitive
    end

    it 'returns failure for invalid domain' do
      result = runner.create_site(domain: :invalid_domain_xyz, engine: engine)
      expect(result[:success]).to be false
      expect(result[:error]).to be_a String
    end
  end

  describe '.dig' do
    let(:site) { engine.create_site(domain: :cognitive) }

    it 'digs successfully' do
      result = runner.dig(site_id: site.id, engine: engine)
      expect(result[:success]).to be true
      expect(result[:dug]).to be true
    end

    it 'returns failure for unknown site' do
      result = runner.dig(site_id: 'bad', engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '.excavate' do
    let(:site) { engine.create_site(domain: :cognitive) }

    it 'excavates successfully' do
      result = runner.excavate(site_id: site.id, engine: engine)
      expect(result[:success]).to be true
      expect(result[:artifact]).to be_a Hash
    end

    it 'returns failure for unknown site' do
      result = runner.excavate(site_id: 'bad', engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '.restore_artifact' do
    it 'restores an artifact' do
      site = engine.create_site(domain: :cognitive)
      a = engine.excavate(site_id: site.id)
      a.decay!(rate: 0.3)
      result = runner.restore_artifact(artifact_id: a.id, boost: 0.2, engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns failure for unknown artifact' do
      result = runner.restore_artifact(artifact_id: 'bad', boost: 0.1, engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '.list_artifacts' do
    before do
      site = engine.create_site(domain: :cognitive)
      3.times { engine.excavate(site_id: site.id) }
    end

    it 'lists all artifacts' do
      result = runner.list_artifacts(engine: engine)
      expect(result[:success]).to be true
      expect(result[:count]).to eq 3
    end

    it 'filters by domain' do
      result = runner.list_artifacts(engine: engine, domain: :cognitive)
      expect(result[:count]).to eq 3
    end

    it 'filters by non-matching domain' do
      result = runner.list_artifacts(engine: engine, domain: :emotional)
      expect(result[:count]).to eq 0
    end
  end

  describe '.archaeology_status' do
    it 'returns status report' do
      result = runner.archaeology_status(engine: engine)
      expect(result[:success]).to be true
      expect(result[:report]).to be_a Hash
    end
  end
end
