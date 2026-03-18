# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/agentic/memory/trace/quota'

RSpec.describe Legion::Extensions::Agentic::Memory::Trace::Quota do
  describe '.new' do
    it 'uses defaults' do
      quota = described_class.new
      expect(quota.max_traces).to eq(10_000)
      expect(quota.max_bytes).to eq(52_428_800)
      expect(quota.eviction).to eq(:lru)
    end

    it 'accepts overrides' do
      quota = described_class.new(max_traces: 500, eviction: :lowest_confidence)
      expect(quota.max_traces).to eq(500)
      expect(quota.eviction).to eq(:lowest_confidence)
    end
  end

  describe '#within_limits?' do
    let(:quota) { described_class.new(max_traces: 100, max_bytes: 1024) }
    let(:store) { double('store') }

    it 'returns true when under limits' do
      allow(store).to receive(:count).and_return(50)
      allow(store).to receive(:total_bytes).and_return(512)
      expect(quota.within_limits?(store)).to be true
    end

    it 'returns false when over trace limit' do
      allow(store).to receive(:count).and_return(200)
      allow(store).to receive(:total_bytes).and_return(512)
      expect(quota.within_limits?(store)).to be false
    end

    it 'returns false when over byte limit' do
      allow(store).to receive(:count).and_return(50)
      allow(store).to receive(:total_bytes).and_return(2048)
      expect(quota.within_limits?(store)).to be false
    end
  end

  describe '#enforce!' do
    let(:quota) { described_class.new(max_traces: 10, max_bytes: 1_048_576) }
    let(:store) { double('store') }

    it 'evicts when over trace limit' do
      allow(store).to receive(:count).and_return(15)
      allow(store).to receive(:total_bytes).and_return(100)
      expect(store).to receive(:delete_least_recently_used).with(count: 5)
      quota.enforce!(store)
    end
  end
end
