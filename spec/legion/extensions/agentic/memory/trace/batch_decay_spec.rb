# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/agentic/memory/trace/persistent_store'
require 'legion/extensions/agentic/memory/trace/batch_decay'

RSpec.describe Legion::Extensions::Agentic::Memory::Trace::BatchDecay do
  describe '.apply!' do
    it 'returns zeros when db unavailable' do
      allow(described_class).to receive(:db_ready?).and_return(false)
      result = described_class.apply!
      expect(result).to eq({ updated: 0, evicted: 0 })
    end
  end

  describe 'DEFAULTS' do
    it 'has sensible rate' do
      expect(described_class::DEFAULTS[:rate]).to eq(0.999)
      expect(described_class::DEFAULTS[:min_confidence]).to eq(0.01)
    end

    it 'specifies interval in hours' do
      expect(described_class::DEFAULTS[:interval_hours]).to eq(1)
    end
  end
end
