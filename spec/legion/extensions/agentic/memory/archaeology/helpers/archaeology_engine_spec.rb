# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Archaeology::Helpers::ArchaeologyEngine do
  let(:engine) { described_class.new }

  describe '#create_site' do
    it 'creates a site with the given domain' do
      site = engine.create_site(domain: :cognitive)
      expect(site.domain).to eq :cognitive
    end

    it 'tracks site in all_sites' do
      engine.create_site(domain: :cognitive)
      expect(engine.all_sites.size).to eq 1
    end

    it 'raises on invalid domain' do
      expect { engine.create_site(domain: :bogus) }.to raise_error(ArgumentError)
    end
  end

  describe '#dig' do
    let(:site) { engine.create_site(domain: :cognitive) }

    it 'returns hash with site survey and dug status' do
      result = engine.dig(site_id: site.id)
      expect(result[:dug]).to be true
      expect(result[:site]).to be_a Hash
    end

    it 'raises for unknown site_id' do
      expect { engine.dig(site_id: 'bad') }.to raise_error(ArgumentError, /site not found/)
    end
  end

  describe '#excavate' do
    let(:site) { engine.create_site(domain: :cognitive) }

    it 'returns an Artifact' do
      expect(engine.excavate(site_id: site.id)).to be_a(
        Legion::Extensions::Agentic::Memory::Archaeology::Helpers::Artifact
      )
    end

    it 'tracks artifact in all_artifacts' do
      engine.excavate(site_id: site.id)
      expect(engine.all_artifacts.size).to eq 1
    end
  end

  describe '#restore_artifact' do
    it 'boosts preservation' do
      site = engine.create_site(domain: :cognitive)
      a = engine.excavate(site_id: site.id)
      a.decay!(rate: 0.3)
      original = a.preservation
      engine.restore_artifact(artifact_id: a.id, boost: 0.2)
      expect(a.preservation).to be > original
    end

    it 'raises for unknown artifact_id' do
      expect { engine.restore_artifact(artifact_id: 'bad') }.to raise_error(ArgumentError)
    end
  end

  describe '#decay_all!' do
    it 'reduces preservation on all artifacts' do
      site = engine.create_site(domain: :cognitive)
      a = engine.excavate(site_id: site.id)
      original = a.preservation
      engine.decay_all!
      expect(a.preservation).to be < original
    end

    it 'prunes artifacts that reach 0.0' do
      site = engine.create_site(domain: :cognitive)
      a = engine.excavate(site_id: site.id)
      a.instance_variable_set(:@preservation_quality, 0.01)
      engine.decay_all!(rate: 0.5)
      expect(engine.all_artifacts).not_to include(a)
    end

    it 'returns remaining artifact count' do
      site = engine.create_site(domain: :cognitive)
      engine.excavate(site_id: site.id)
      expect(engine.decay_all!).to be_a Integer
    end
  end

  describe '#artifacts_by_type' do
    it 'filters by artifact_type' do
      site = engine.create_site(domain: :cognitive)
      3.times { engine.excavate(site_id: site.id) }
      first_type = engine.all_artifacts.first.artifact_type
      results = engine.artifacts_by_type(first_type)
      expect(results).to all(have_attributes(artifact_type: first_type))
    end
  end

  describe '#artifacts_by_domain' do
    it 'returns matching artifacts' do
      site = engine.create_site(domain: :cognitive)
      engine.excavate(site_id: site.id)
      expect(engine.artifacts_by_domain(:cognitive).size).to eq 1
    end

    it 'returns empty for non-matching domain' do
      site = engine.create_site(domain: :cognitive)
      engine.excavate(site_id: site.id)
      expect(engine.artifacts_by_domain(:emotional)).to be_empty
    end
  end

  describe '#best_preserved' do
    it 'returns artifacts sorted by preservation descending' do
      site = engine.create_site(domain: :cognitive)
      5.times { engine.excavate(site_id: site.id) }
      best = engine.best_preserved(limit: 3)
      preservations = best.map(&:preservation)
      expect(preservations).to eq preservations.sort.reverse
    end
  end

  describe '#most_fragile' do
    it 'returns only fragments' do
      site = engine.create_site(domain: :cognitive)
      3.times { engine.excavate(site_id: site.id) }
      engine.all_artifacts.first.instance_variable_set(:@preservation_quality, 0.1)
      fragile = engine.most_fragile
      expect(fragile).to all(be_fragment)
    end
  end

  describe '#site_report' do
    it 'returns site data with artifacts' do
      site = engine.create_site(domain: :cognitive)
      engine.excavate(site_id: site.id)
      report = engine.site_report(site_id: site.id)
      expect(report).to have_key(:artifacts)
    end
  end

  describe '#archaeology_report' do
    it 'returns comprehensive report' do
      site = engine.create_site(domain: :cognitive)
      engine.excavate(site_id: site.id)
      report = engine.archaeology_report
      %i[total_artifacts total_sites type_breakdown domain_breakdown
         depth_breakdown avg_preservation avg_integrity fragment_count
         ancient_count sites].each do |key|
        expect(report).to have_key(key)
      end
    end

    it 'returns correct counts' do
      site = engine.create_site(domain: :cognitive)
      3.times { engine.excavate(site_id: site.id) }
      expect(engine.archaeology_report[:total_artifacts]).to eq 3
    end

    it 'works empty' do
      expect(engine.archaeology_report[:total_artifacts]).to eq 0
    end
  end
end
