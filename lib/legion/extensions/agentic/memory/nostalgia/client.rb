# frozen_string_literal: true

require 'legion/extensions/agentic/memory/nostalgia/helpers/constants'
require 'legion/extensions/agentic/memory/nostalgia/helpers/nostalgic_memory'
require 'legion/extensions/agentic/memory/nostalgia/helpers/nostalgia_event'
require 'legion/extensions/agentic/memory/nostalgia/helpers/nostalgia_engine'
require 'legion/extensions/agentic/memory/nostalgia/runners/recall'
require 'legion/extensions/agentic/memory/nostalgia/runners/analysis'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Nostalgia
          class Client
            include Runners::Recall
            include Runners::Analysis

            def initialize(engine: nil)
              @nostalgia_engine = engine || Helpers::NostalgiaEngine.new
            end

            private

            attr_reader :nostalgia_engine
          end
        end
      end
    end
  end
end
