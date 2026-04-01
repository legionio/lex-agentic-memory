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

  describe 'record_trace (async dispatch)' do
    let(:runner_double) do
      dbl = double('runner')
      store_dbl = double('store', flush: nil)
      allow(dbl).to receive(:store_trace)
      allow(dbl).to receive(:default_store).and_return(store_dbl)
      dbl
    end

    before do
      described_class.instance_variable_set(:@active, true)
      described_class.instance_variable_set(:@recent, {})
      described_class.instance_variable_set(:@runner, runner_double)
    end

    it 'returns a Thread object (fire-and-forget dispatch)' do
      result = described_class.send(:record_trace, 'something broke', :error)
      expect(result).to be_a(Thread)
      result.join
    end

    it 'calls store_trace on the runner inside the thread' do
      thread = described_class.send(:record_trace, '[mycomponent] disk full', :error)
      thread.join
      expect(runner_double).to have_received(:store_trace).with(
        hash_including(
          type:            :episodic,
          content_payload: '[mycomponent] disk full',
          domain_tags:     %w[error mycomponent],
          unresolved:      true
        )
      )
    end

    it 'uses fatal valence and intensity for :fatal level' do
      thread = described_class.send(:record_trace, 'total meltdown', :fatal)
      thread.join
      expect(runner_double).to have_received(:store_trace).with(
        hash_including(
          emotional_valence:   Legion::Extensions::Agentic::Memory::Trace::Helpers::ErrorTracer::FATAL_VALENCE,
          emotional_intensity: Legion::Extensions::Agentic::Memory::Trace::Helpers::ErrorTracer::FATAL_INTENSITY
        )
      )
    end

    it 'returns nil (debounced) when same message is within the window' do
      described_class.send(:record_trace, 'repeated error', :error)&.join
      result = described_class.send(:record_trace, 'repeated error', :error)
      expect(result).to be_nil
    end

    it 'returns nil for blank messages without raising' do
      expect(described_class.send(:record_trace, '', :error)).to be_nil
    end

    it 'returns nil when store_trace raises, without propagating the error' do
      allow(runner_double).to receive(:store_trace).and_raise(StandardError, 'db down')
      thread = described_class.send(:record_trace, 'store failure', :error)
      expect { thread.join }.not_to raise_error
    end
  end
end
