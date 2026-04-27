# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Consolidation::PreCompact do
  let(:store) do
    Class.new do
      attr_reader :traces, :flushed

      def initialize
        @traces = []
        @flushed = false
      end

      def store(trace)
        @traces << trace
      end

      def flush
        @flushed = true
      end
    end.new
  end

  let(:session) do
    [
      { role: :user, content: 'We decided to use local memory because vLLM was failing.' },
      { role: :assistant, content: 'I found the root cause and fixed the startup crash.' },
      { role: :user, content: 'Always keep embeddings local.' }
    ]
  end

  it 'extracts high-signal compaction details and stores them as traces' do
    result = described_class.before_compact(session: session, agent_id: 'agent-1', store: store)

    expect(result[:success]).to be true
    expect(result[:saved]).to be >= 3
    expect(store.flushed).to be true
    expect(store.traces.map { |trace| trace[:partition_id] }.uniq).to eq(['agent-1'])
    expect(store.traces.flat_map { |trace| trace[:domain_tags] }).to include('pre_compact', 'decisions', 'preferences', 'problems')
  end

  it 'promotes extracted entries to Apollo when an ingest writer is provided' do
    apollo = class_double('Apollo', ingest: true)

    described_class.before_compact(session: session, agent_id: 'agent-1', store: store, apollo: apollo)

    expect(apollo).to have_received(:ingest).at_least(:once)
  end
end
