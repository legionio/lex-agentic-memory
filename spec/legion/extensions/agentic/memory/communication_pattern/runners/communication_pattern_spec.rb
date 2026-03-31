# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/agentic/memory/communication_pattern/helpers/constants'
require 'legion/extensions/agentic/memory/communication_pattern/helpers/pattern_analyzer'
require 'legion/extensions/agentic/memory/communication_pattern/runners/communication_pattern'

RSpec.describe Legion::Extensions::Agentic::Memory::CommunicationPattern::Runners::CommunicationPattern do
  let(:host) { Object.new.extend(described_module) }
  let(:described_module) { described_class }

  before { host.instance_variable_set(:@analyzers, nil) }

  describe '#update_patterns' do
    let(:traces) do
      [
        { trace_id: 'tr1', trace_type: :episodic, created_at: Time.utc(2026, 3, 31, 9, 0),
          content_payload: { channel: 'teams', direct_address: true }, domain_tags: %w[partner],
          source_agent_id: 'partner-1' },
        { trace_id: 'tr2', trace_type: :episodic, created_at: Time.utc(2026, 3, 31, 14, 0),
          content_payload: { channel: 'cli', direct_address: false }, domain_tags: %w[partner],
          source_agent_id: 'partner-1' }
      ]
    end

    it 'processes traces and returns result' do
      result = host.update_patterns(agent_id: 'partner-1', traces: traces)
      expect(result[:success]).to be true
      expect(result[:trace_count]).to eq(2)
    end

    it 'returns channel preference' do
      result = host.update_patterns(agent_id: 'partner-1', traces: traces)
      expect(result[:channel_preference]).to be_an(Array)
    end

    it 'returns direct address frequency' do
      result = host.update_patterns(agent_id: 'partner-1', traces: traces)
      expect(result[:direct_address_frequency]).to be_within(0.01).of(0.5)
    end
  end

  describe '#analyze_patterns' do
    it 'returns current patterns for an agent' do
      host.update_patterns(agent_id: 'p1', traces: [
        { trace_id: 't1', trace_type: :episodic, created_at: Time.now.utc,
          content_payload: { channel: 'teams' }, domain_tags: [], source_agent_id: 'p1' }
      ])
      result = host.analyze_patterns(agent_id: 'p1')
      expect(result).to have_key(:time_of_day_distribution)
      expect(result).to have_key(:channel_preference)
    end

    it 'returns empty result for unknown agent' do
      result = host.analyze_patterns(agent_id: 'unknown')
      expect(result[:trace_count]).to eq(0)
    end
  end

  describe '#pattern_stats' do
    it 'returns stats hash' do
      result = host.pattern_stats(agent_id: 'p1')
      expect(result).to have_key(:trace_count)
    end
  end
end
