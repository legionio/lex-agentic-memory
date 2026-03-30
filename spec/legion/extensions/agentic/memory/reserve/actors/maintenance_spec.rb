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

require 'legion/extensions/agentic/memory/reserve/actors/maintenance'

RSpec.describe Legion::Extensions::Agentic::Memory::Reserve::Actor::Maintenance do
  subject(:actor) { described_class.new }

  it { expect(actor.runner_class).to eq(Legion::Extensions::Agentic::Memory::Reserve::Runners::CognitiveReserve) }
  it { expect(actor.runner_function).to eq('update_cognitive_reserve') }
  it { expect(actor.time).to eq(60) }
  it { expect(actor.use_runner?).to be false }
  it { expect(actor.check_subtask?).to be false }
  it { expect(actor.generate_task?).to be false }
end
