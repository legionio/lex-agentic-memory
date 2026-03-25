# frozen_string_literal: true

module Legion
  module Extensions
    module Actors
      class Every # rubocop:disable Lint/EmptyClass
      end
    end
  end
end
$LOADED_FEATURES << 'legion/extensions/actors/every'

require 'legion/extensions/agentic/memory/trace/actors/quota'

RSpec.describe Legion::Extensions::Agentic::Memory::Trace::Actor::Quota do
  subject(:actor) { described_class.new }

  it { expect(actor.runner_class).to eq(Legion::Extensions::Agentic::Memory::Trace::Runners::Consolidation) }
  it { expect(actor.runner_function).to eq('enforce_quota') }
  it { expect(actor.time).to eq(300) }
  it { expect(actor.use_runner?).to be false }
  it { expect(actor.check_subtask?).to be false }
  it { expect(actor.generate_task?).to be false }
end
