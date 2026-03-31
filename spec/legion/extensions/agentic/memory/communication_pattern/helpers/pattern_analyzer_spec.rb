# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/agentic/memory/communication_pattern/helpers/constants'
require 'legion/extensions/agentic/memory/communication_pattern/helpers/pattern_analyzer'

RSpec.describe Legion::Extensions::Agentic::Memory::CommunicationPattern::Helpers::PatternAnalyzer do
  subject(:analyzer) { described_class.new(agent_id: 'partner-1') }

  let(:trace_9am) do
    { trace_id: 'tr1', trace_type: :episodic, created_at: Time.utc(2026, 3, 31, 9, 0),
      content_payload: { channel: 'teams', direct_address: true, agent_id: 'partner-1' },
      domain_tags: %w[partner observation], source_agent_id: 'partner-1' }
  end

  let(:trace_2pm) do
    { trace_id: 'tr2', trace_type: :episodic, created_at: Time.utc(2026, 3, 31, 14, 0),
      content_payload: { channel: 'cli', direct_address: false, agent_id: 'partner-1' },
      domain_tags: %w[partner observation work], source_agent_id: 'partner-1' }
  end

  describe '#update_from_traces' do
    it 'processes an array of traces' do
      analyzer.update_from_traces([trace_9am, trace_2pm])
      expect(analyzer.trace_count).to eq(2)
    end

    it 'marks dirty' do
      analyzer.update_from_traces([trace_9am])
      expect(analyzer).to be_dirty
    end
  end

  describe '#time_of_day_distribution' do
    before { analyzer.update_from_traces([trace_9am, trace_2pm]) }

    it 'returns 24-bucket histogram' do
      dist = analyzer.time_of_day_distribution
      expect(dist.size).to eq(24)
    end

    it 'has counts in the right buckets' do
      dist = analyzer.time_of_day_distribution
      expect(dist[9]).to eq(1)
      expect(dist[14]).to eq(1)
      expect(dist[0]).to eq(0)
    end
  end

  describe '#day_of_week_distribution' do
    before { analyzer.update_from_traces([trace_9am]) }

    it 'returns 7-bucket histogram' do
      dist = analyzer.day_of_week_distribution
      expect(dist.size).to eq(7)
    end
  end

  describe '#channel_preference' do
    before { analyzer.update_from_traces([trace_9am, trace_2pm, trace_9am.merge(trace_id: 'tr3')]) }

    it 'ranks channels by frequency' do
      prefs = analyzer.channel_preference
      expect(prefs.first).to eq('teams')
    end
  end

  describe '#direct_address_frequency' do
    before { analyzer.update_from_traces([trace_9am, trace_2pm]) }

    it 'computes ratio of direct address traces' do
      ratio = analyzer.direct_address_frequency
      expect(ratio).to be_within(0.01).of(0.5)
    end
  end

  describe '#topic_clustering' do
    before { analyzer.update_from_traces([trace_9am, trace_2pm]) }

    it 'returns domain tag frequencies' do
      topics = analyzer.topic_clustering
      expect(topics).to have_key('partner')
      expect(topics['partner']).to eq(2)
    end
  end

  describe '#consistency' do
    it 'returns 0.0 with no data' do
      expect(analyzer.consistency).to eq(0.0)
    end

    it 'returns positive value with data' do
      analyzer.update_from_traces([trace_9am, trace_2pm])
      expect(analyzer.consistency).to eq(0.0)
    end
  end

  describe 'Apollo persistence' do
    describe '#to_apollo_entries' do
      before { analyzer.update_from_traces([trace_9am]) }

      it 'returns entries with correct tags' do
        entries = analyzer.to_apollo_entries
        expect(entries.first[:tags]).to include('bond', 'communication_pattern', 'partner-1')
      end
    end

    describe '#from_apollo' do
      let(:mock_store) { double('apollo_local') }

      it 'restores state' do
        analyzer.update_from_traces([trace_9am, trace_2pm])
        content = analyzer.send(:serialize, analyzer.send(:state_hash))

        new_analyzer = described_class.new(agent_id: 'partner-1')
        allow(mock_store).to receive(:query)
          .and_return({ success: true, results: [{ content: content }] })

        expect(new_analyzer.from_apollo(store: mock_store)).to be true
        expect(new_analyzer.trace_count).to eq(2)
      end
    end

    describe '#mark_clean!' do
      it 'clears dirty flag' do
        analyzer.update_from_traces([trace_9am])
        analyzer.mark_clean!
        expect(analyzer).not_to be_dirty
      end
    end
  end
end
