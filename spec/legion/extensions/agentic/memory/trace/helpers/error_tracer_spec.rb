# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Memory::Trace::Helpers::ErrorTracer do
  # Capture originals before any example runs so we can restore after each
  original_error = Legion::Logging.method(:error)
  original_fatal = Legion::Logging.method(:fatal)

  before do
    # Reset state between examples
    described_class.instance_variable_set(:@active, nil)
    described_class.instance_variable_set(:@recent, nil)
    described_class.instance_variable_set(:@runner, nil)
  end

  after do
    # Restore logging singleton methods to prevent cross-test side effects
    Legion::Logging.define_singleton_method(:error, &original_error)
    Legion::Logging.define_singleton_method(:fatal, &original_fatal)
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
