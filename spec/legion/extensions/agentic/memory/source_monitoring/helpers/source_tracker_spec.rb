# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::SourceMonitoring::Helpers::SourceTracker do
  subject(:tracker) { described_class.new }

  let(:constants) { Legion::Extensions::Agentic::Memory::SourceMonitoring::Helpers::Constants }

  describe '#record_source' do
    it 'creates a source record' do
      rec = tracker.record_source(content_id: 'fact:one', source: :external_perception)
      expect(rec).to be_a(Legion::Extensions::Agentic::Memory::SourceMonitoring::Helpers::SourceRecord)
      expect(tracker.records.size).to eq(1)
    end

    it 'rejects invalid sources' do
      expect(tracker.record_source(content_id: 'x', source: :bogus)).to be_nil
    end

    it 'enforces MAX_RECORDS' do
      constants::MAX_RECORDS.times do |i|
        tracker.record_source(content_id: "fact:#{i}", source: :external_perception)
      end
      expect(tracker.record_source(content_id: 'overflow', source: :external_perception)).to be_nil
    end
  end

  describe '#attribute' do
    it 'returns records for a content_id sorted by confidence' do
      tracker.record_source(content_id: 'fact:x', source: :external_perception, confidence: 0.5)
      tracker.record_source(content_id: 'fact:x', source: :memory_retrieval, confidence: 0.8)
      results = tracker.attribute(content_id: 'fact:x')
      expect(results.size).to eq(2)
      expect(results.first.confidence).to be > results.last.confidence
    end

    it 'returns empty for unknown content' do
      expect(tracker.attribute(content_id: 'nope')).to be_empty
    end
  end

  describe '#verify_source' do
    it 'verifies a record' do
      rec = tracker.record_source(content_id: 'fact:x', source: :external_perception)
      result = tracker.verify_source(record_id: rec.id)
      expect(result.verified).to be true
    end

    it 'returns nil for unknown record' do
      expect(tracker.verify_source(record_id: :nope)).to be_nil
    end

    it 'logs attribution' do
      rec = tracker.record_source(content_id: 'fact:x', source: :external_perception)
      tracker.verify_source(record_id: rec.id)
      expect(tracker.attribution_log.size).to eq(1)
    end
  end

  describe '#correct_source' do
    it 'corrects the source' do
      rec = tracker.record_source(content_id: 'fact:x', source: :external_perception)
      result = tracker.correct_source(record_id: rec.id, new_source: :memory_retrieval)
      expect(result.source).to eq(:memory_retrieval)
    end

    it 'rejects invalid new source' do
      rec = tracker.record_source(content_id: 'fact:x', source: :external_perception)
      expect(tracker.correct_source(record_id: rec.id, new_source: :bogus)).to be_nil
    end
  end

  describe '#reality_check' do
    it 'returns status for known content' do
      tracker.record_source(content_id: 'fact:x', source: :external_perception)
      result = tracker.reality_check(content_id: 'fact:x')
      expect(result[:status]).to eq(:real)
    end

    it 'returns unknown for unknown content' do
      result = tracker.reality_check(content_id: 'nope')
      expect(result[:status]).to eq(:unknown)
    end
  end

  describe '#confused_records' do
    it 'returns records with source confusion and low confidence' do
      rec = tracker.record_source(content_id: 'fact:x', source: :external_perception, confidence: 0.3)
      confused = tracker.confused_records
      expect(confused.size).to eq(1)
      expect(confused.first[:id]).to eq(rec.id)
    end
  end

  describe '#records_by_source' do
    it 'filters by source type' do
      tracker.record_source(content_id: 'a', source: :external_perception)
      tracker.record_source(content_id: 'b', source: :imagination)
      results = tracker.records_by_source(source: :imagination)
      expect(results.size).to eq(1)
    end
  end

  describe '#attribution_accuracy' do
    it 'returns 0 with no verifications' do
      expect(tracker.attribution_accuracy).to eq(0.0)
    end

    it 'returns ratio of hits to total' do
      rec = tracker.record_source(content_id: 'a', source: :external_perception)
      tracker.verify_source(record_id: rec.id)
      rec2 = tracker.record_source(content_id: 'b', source: :imagination)
      tracker.correct_source(record_id: rec2.id, new_source: :memory_retrieval)
      expect(tracker.attribution_accuracy).to eq(0.5)
    end
  end

  describe '#decay_all' do
    it 'decays records and removes faded ones' do
      tracker.record_source(content_id: 'faint', source: :inference, confidence: 0.12)
      20.times { tracker.decay_all }
      expect(tracker.records.values.none? { |r| r.content_id == 'faint' }).to be true
    end

    it 'preserves verified records' do
      rec = tracker.record_source(content_id: 'solid', source: :external_perception, confidence: 0.12)
      tracker.verify_source(record_id: rec.id)
      20.times { tracker.decay_all }
      expect(tracker.records).to have_key(rec.id)
    end
  end

  describe '#to_h' do
    it 'returns summary hash' do
      h = tracker.to_h
      expect(h).to include(:total_records, :verified_count, :confused_count,
                           :accuracy, :source_distribution, :attribution_log_size)
    end
  end
end
