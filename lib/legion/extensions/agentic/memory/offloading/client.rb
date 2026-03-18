# frozen_string_literal: true

require 'legion/extensions/agentic/memory/offloading/helpers/constants'
require 'legion/extensions/agentic/memory/offloading/helpers/external_store'
require 'legion/extensions/agentic/memory/offloading/helpers/offloaded_item'
require 'legion/extensions/agentic/memory/offloading/helpers/offloading_engine'
require 'legion/extensions/agentic/memory/offloading/runners/cognitive_offloading'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Offloading
          class Client
            include Runners::CognitiveOffloading

            def initialize(engine: nil, **)
              @offloading_engine = engine || Helpers::OffloadingEngine.new
            end

            private

            attr_reader :offloading_engine
          end
        end
      end
    end
  end
end
