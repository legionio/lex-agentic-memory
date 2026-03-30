# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Memory::Trace::Helpers::ErrorTracer do
  before do
    # Reset state between examples
    described_class.instance_variable_set(:@active, nil)
    described_class.instance_variable_set(:@recent, nil)
    described_class.instance_variable_set(:@runner, nil)
  end

  describe '.setup' do
    it 'activates without raising' do
      expect { described_class.setup }.not_to raise_error
      expect(described_class.active?).to be true
    end

    it 'is idempotent' do
      described_class.setup
      described_class.setup
      expect(described_class.active?).to be true
    end
  end

  describe '.active?' do
    it 'returns false before setup' do
      expect(described_class.active?).to be false
    end

    it 'returns true after setup' do
      described_class.setup
      expect(described_class.active?).to be true
    end
  end
end
