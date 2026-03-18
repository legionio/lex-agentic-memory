# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/agentic/memory/trace/persistent_store'

RSpec.describe Legion::Extensions::Agentic::Memory::Trace::PersistentStore do
  let(:store) { described_class.new(agent_id: 'test-agent') }

  describe '#read' do
    it 'returns empty when db unavailable' do
      allow(store).to receive(:db_ready?).and_return(false)
      expect(store.read).to eq([])
    end
  end

  describe '#write' do
    it 'returns nil when db unavailable' do
      allow(store).to receive(:db_ready?).and_return(false)
      expect(store.write(trace_type: :episodic, content: 'test')).to be_nil
    end
  end

  describe '#count' do
    it 'returns 0 when db unavailable' do
      allow(store).to receive(:db_ready?).and_return(false)
      expect(store.count).to eq(0)
    end
  end

  describe '#total_bytes' do
    it 'returns 0 when db unavailable' do
      allow(store).to receive(:db_ready?).and_return(false)
      expect(store.total_bytes).to eq(0)
    end
  end

  describe '#delete_lowest_confidence' do
    it 'returns 0 when db unavailable' do
      allow(store).to receive(:db_ready?).and_return(false)
      expect(store.delete_lowest_confidence).to eq(0)
    end
  end

  describe '#delete_least_recently_used' do
    it 'returns 0 when db unavailable' do
      allow(store).to receive(:db_ready?).and_return(false)
      expect(store.delete_least_recently_used).to eq(0)
    end
  end
end
