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

require 'legion/extensions/agentic/memory/nostalgia/actors/maintenance'

RSpec.describe Legion::Extensions::Agentic::Memory::Nostalgia::Actor::Maintenance do
  subject(:actor) { described_class.new }

  it { expect(actor.runner_class).to eq(Legion::Extensions::Agentic::Memory::Nostalgia::Runners::Recall) }
  it { expect(actor.runner_function).to eq('age_memories') }
  it { expect(actor.time).to eq(120) }
  it { expect(actor.use_runner?).to be false }
  it { expect(actor.check_subtask?).to be false }
  it { expect(actor.generate_task?).to be false }
end
