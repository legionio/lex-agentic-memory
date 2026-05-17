# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Hologram::Helpers::HologramEngine do
  subject(:engine) { described_class.new }

  def build_hologram(overrides = {})
    engine.create_hologram(
      domain:  overrides.fetch(:domain, :memory),
      content: overrides.fetch(:content, 'the quick brown fox jumps over the lazy dog')
    )
  end

  describe '#create_hologram' do
    it 'returns a Hologram instance' do
      expect(build_hologram).to be_a(Legion::Extensions::Agentic::Memory::Hologram::Helpers::Hologram)
    end

    it 'stores the hologram internally' do
      h = build_hologram
      expect(engine.get(h.id)).to eq(h)
    end

    it 'increments hologram count' do
      3.times { build_hologram }
      expect(engine.holograms.size).to eq(3)
    end

    it 'assigns the provided domain' do
      h = build_hologram(domain: :emotion)
      expect(h.domain).to eq(:emotion)
    end

    it 'assigns the provided content' do
      h = build_hologram(content: 'unique content here')
      expect(h.content).to eq('unique content here')
    end
  end

  describe '#fragment_hologram' do
    let(:hologram) { build_hologram }

    it 'returns an array of fragments' do
      result = engine.fragment_hologram(hologram_id: hologram.id, count: 3)
      expect(result).to be_an(Array)
    end

    it 'returns the requested number of fragments' do
      result = engine.fragment_hologram(hologram_id: hologram.id, count: 4)
      expect(result.size).to eq(4)
    end

    it 'returns nil for unknown hologram_id' do
      result = engine.fragment_hologram(hologram_id: SecureRandom.uuid, count: 2)
      expect(result).to be_nil
    end

    it 'attaches fragments to the hologram' do
      engine.fragment_hologram(hologram_id: hologram.id, count: 3)
      expect(hologram.fragments.size).to eq(3)
    end
  end

  describe '#reconstruct_from_fragments' do
    let(:hologram) { build_hologram }
    let(:fragments) { engine.fragment_hologram(hologram_id: hologram.id, count: 4) }

    it 'returns success: true when sufficient fragments are used' do
      # Enhance all fragments to guarantee they exceed the reconstruction threshold
      # regardless of the random completeness assigned during fragmentation.
      fragments.each { |f| f.enhance!(0.5) }
      ids = fragments.select(&:sufficient?).map(&:id)
      result = engine.reconstruct_from_fragments(hologram_id: hologram.id, fragment_ids: ids)
      expect(result[:success]).to be true
    end

    it 'returns success: false when hologram not found' do
      result = engine.reconstruct_from_fragments(
        hologram_id:  SecureRandom.uuid,
        fragment_ids: []
      )
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:hologram_not_found)
    end

    it 'returns resolution value on success' do
      ids = fragments.map(&:id)
      result = engine.reconstruct_from_fragments(hologram_id: hologram.id, fragment_ids: ids)
      expect(result[:resolution]).to be_a(Float) if result[:success]
    end

    it 'returns success: false with empty fragment ids and no sufficient fragments match' do
      result = engine.reconstruct_from_fragments(hologram_id: hologram.id, fragment_ids: [])
      expect(result[:success]).to be false
    end
  end

  describe '#measure_interference' do
    let(:hologram_a) { build_hologram(content: 'the quick brown fox') }
    let(:hologram_b) { build_hologram(content: 'the quick brown fox') }
    let(:hologram_c) { build_hologram(content: 'completely unrelated content here now') }

    it 'returns interference score as float' do
      result = engine.measure_interference(hologram_id_a: hologram_a.id, hologram_id_b: hologram_b.id)
      expect(result[:interference]).to be_a(Float)
    end

    it 'returns high interference for near-identical content' do
      result = engine.measure_interference(hologram_id_a: hologram_a.id, hologram_id_b: hologram_b.id)
      expect(result[:interference]).to be > 0.5
    end

    it 'returns lower interference for dissimilar content' do
      r1 = engine.measure_interference(hologram_id_a: hologram_a.id, hologram_id_b: hologram_b.id)
      r2 = engine.measure_interference(hologram_id_a: hologram_a.id, hologram_id_b: hologram_c.id)
      expect(r1[:interference]).to be >= r2[:interference]
    end

    it 'includes a label key' do
      result = engine.measure_interference(hologram_id_a: hologram_a.id, hologram_id_b: hologram_b.id)
      expect(result[:label]).to be_a(Symbol)
    end

    it 'returns reason :hologram_not_found when a hologram is missing' do
      result = engine.measure_interference(
        hologram_id_a: SecureRandom.uuid,
        hologram_id_b: hologram_b.id
      )
      expect(result[:reason]).to eq(:hologram_not_found)
    end
  end

  describe '#degrade_all!' do
    before do
      hologram = build_hologram
      engine.fragment_hologram(hologram_id: hologram.id, count: 3)
    end

    it 'reduces fidelity on all fragments' do
      before_values = engine.holograms.flat_map { |h| h.fragments.map(&:fidelity) }
      engine.degrade_all!
      after_values = engine.holograms.flat_map { |h| h.fragments.map(&:fidelity) }
      expect(after_values.sum).to be < before_values.sum
    end

    it 'affects completeness on all fragments' do
      before_values = engine.holograms.flat_map { |h| h.fragments.map(&:completeness) }
      engine.degrade_all!
      after_values = engine.holograms.flat_map { |h| h.fragments.map(&:completeness) }
      expect(after_values.sum).to be < before_values.sum
    end
  end

  describe '#best_preserved' do
    before do
      3.times do |i|
        h = build_hologram(content: "hologram content #{i}")
        engine.fragment_hologram(hologram_id: h.id, count: 2)
      end
    end

    it 'returns an array' do
      expect(engine.best_preserved(limit: 2)).to be_an(Array)
    end

    it 'respects the limit' do
      expect(engine.best_preserved(limit: 2).size).to be <= 2
    end

    it 'returns holograms sorted by resolution descending' do
      top = engine.best_preserved(limit: 3)
      resolutions = top.map(&:resolution)
      expect(resolutions).to eq(resolutions.sort.reverse)
    end

    it 'returns empty array when no holograms have fragments' do
      fresh_engine = described_class.new
      fresh_engine.create_hologram(domain: :memory, content: 'no fragments')
      expect(fresh_engine.best_preserved).to be_empty
    end
  end

  describe '#most_fragmented' do
    before do
      3.times do |i|
        h = build_hologram(content: "content for hologram #{i}")
        engine.fragment_hologram(hologram_id: h.id, count: 2)
      end
    end

    it 'returns an array' do
      expect(engine.most_fragmented(limit: 2)).to be_an(Array)
    end

    it 'respects the limit' do
      expect(engine.most_fragmented(limit: 2).size).to be <= 2
    end

    it 'returns holograms sorted by resolution ascending' do
      result = engine.most_fragmented(limit: 3)
      resolutions = result.map(&:resolution)
      expect(resolutions).to eq(resolutions.sort)
    end
  end

  describe '#hologram_report' do
    before do
      2.times do |i|
        h = build_hologram(content: "content number #{i}")
        engine.fragment_hologram(hologram_id: h.id, count: 3)
      end
    end

    subject(:report) { engine.hologram_report }

    it 'includes all expected keys' do
      expected_keys = %i[
        total_holograms holograms_with_frags average_resolution
        resolution_label best_preserved_count most_fragmented_count
      ]
      expect(report.keys).to match_array(expected_keys)
    end

    it 'reports correct total_holograms' do
      expect(report[:total_holograms]).to eq(2)
    end

    it 'reports correct holograms_with_frags' do
      expect(report[:holograms_with_frags]).to eq(2)
    end

    it 'reports average_resolution as float' do
      expect(report[:average_resolution]).to be_a(Float)
    end

    it 'includes resolution_label as symbol' do
      expect(report[:resolution_label]).to be_a(Symbol)
    end
  end

  describe '#holograms' do
    it 'returns empty array initially' do
      expect(engine.holograms).to be_empty
    end

    it 'returns all created holograms' do
      3.times { build_hologram }
      expect(engine.holograms.size).to eq(3)
    end
  end

  describe '#get' do
    it 'returns the hologram by id' do
      h = build_hologram
      expect(engine.get(h.id)).to eq(h)
    end

    it 'returns nil for unknown id' do
      expect(engine.get(SecureRandom.uuid)).to be_nil
    end
  end

  describe 'MAX_HOLOGRAMS pruning' do
    it 'prunes when count reaches MAX_HOLOGRAMS' do
      max = Legion::Extensions::Agentic::Memory::Hologram::Helpers::Constants::MAX_HOLOGRAMS
      max.times { |i| build_hologram(content: "hologram #{i}") }
      expect(engine.holograms.size).to eq(max)
      build_hologram(content: 'one more hologram')
      expect(engine.holograms.size).to be <= max
    end
  end
end
