# frozen_string_literal: true

require 'legion/extensions/agentic/memory/source_monitoring/runners/source_monitoring'

RSpec.describe Legion::Extensions::Agentic::Memory::SourceMonitoring::Runners::SourceMonitoring do
  let(:tracker) { Legion::Extensions::Agentic::Memory::SourceMonitoring::Helpers::SourceTracker.new }
  let(:host) do
    obj = Object.new
    obj.extend(described_class)
    obj.instance_variable_set(:@tracker, tracker)
    obj
  end

  describe '#record_source' do
    it 'records successfully' do
      result = host.record_source(content_id: 'fact:x', source: :external_perception)
      expect(result[:success]).to be true
      expect(result[:record][:source]).to eq(:external_perception)
    end

    it 'fails for invalid source' do
      result = host.record_source(content_id: 'fact:x', source: :bogus)
      expect(result[:success]).to be false
    end
  end

  describe '#attribute_source' do
    it 'returns matching records' do
      host.record_source(content_id: 'fact:x', source: :external_perception)
      result = host.attribute_source(content_id: 'fact:x')
      expect(result[:count]).to eq(1)
    end
  end

  describe '#verify_source' do
    it 'verifies a record' do
      rec = host.record_source(content_id: 'fact:x', source: :external_perception)
      result = host.verify_source(record_id: rec[:record][:id])
      expect(result[:success]).to be true
      expect(result[:record][:verified]).to be true
    end

    it 'fails for unknown record' do
      result = host.verify_source(record_id: :nope)
      expect(result[:success]).to be false
    end
  end

  describe '#correct_source' do
    it 'corrects a source' do
      rec = host.record_source(content_id: 'fact:x', source: :external_perception)
      result = host.correct_source(record_id: rec[:record][:id], new_source: :memory_retrieval)
      expect(result[:success]).to be true
      expect(result[:record][:source]).to eq(:memory_retrieval)
    end
  end

  describe '#reality_check' do
    it 'returns reality status' do
      host.record_source(content_id: 'fact:x', source: :imagination)
      result = host.reality_check(content_id: 'fact:x')
      expect(result[:status]).to eq(:imagined)
    end
  end

  describe '#confused_sources' do
    it 'returns confused records' do
      result = host.confused_sources
      expect(result[:success]).to be true
    end
  end

  describe '#sources_by_type' do
    it 'filters by source type' do
      host.record_source(content_id: 'a', source: :inference)
      result = host.sources_by_type(source: :inference)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#attribution_accuracy' do
    it 'returns accuracy' do
      result = host.attribution_accuracy
      expect(result[:success]).to be true
    end
  end

  describe '#update_source_monitoring' do
    it 'decays and returns count' do
      result = host.update_source_monitoring
      expect(result[:success]).to be true
    end
  end

  describe '#source_monitoring_stats' do
    it 'returns stats' do
      result = host.source_monitoring_stats
      expect(result[:success]).to be true
      expect(result[:stats]).to include(:total_records)
    end
  end
end
