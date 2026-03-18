# frozen_string_literal: true

# Stub the framework actor base class since legionio gem is not available in test
module Legion
  module Extensions
    module Actors
      class Every # rubocop:disable Lint/EmptyClass
      end
    end
  end
end

# Intercept the require in the actor file so it doesn't fail
$LOADED_FEATURES << 'legion/extensions/actors/every'

require 'legion/extensions/agentic/memory/trace/actors/decay'

RSpec.describe Legion::Extensions::Agentic::Memory::Trace::Actor::Decay do
  subject(:actor) { described_class.new }

  describe '#runner_class' do
    it 'returns the Consolidation module' do
      expect(actor.runner_class).to eq(Legion::Extensions::Agentic::Memory::Trace::Runners::Consolidation)
    end
  end

  describe '#runner_function' do
    it 'returns decay_cycle' do
      expect(actor.runner_function).to eq('decay_cycle')
    end
  end

  describe '#time' do
    it 'returns 60 seconds' do
      expect(actor.time).to eq(60)
    end
  end

  describe '#run_now?' do
    it 'returns false' do
      expect(actor.run_now?).to be false
    end
  end

  describe '#use_runner?' do
    it 'returns false' do
      expect(actor.use_runner?).to be false
    end
  end

  describe '#check_subtask?' do
    it 'returns false' do
      expect(actor.check_subtask?).to be false
    end
  end

  describe '#generate_task?' do
    it 'returns false' do
      expect(actor.generate_task?).to be false
    end
  end
end
