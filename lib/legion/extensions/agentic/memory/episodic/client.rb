# frozen_string_literal: true

require 'legion/extensions/agentic/memory/episodic/runners/episodic_buffer'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Episodic
          class Client
            include Legion::Extensions::Agentic::Memory::Episodic::Runners::EpisodicBuffer

            def initialize(store: nil, **)
              @default_store = store || Helpers::EpisodicStore.new
            end

            private

            attr_reader :default_store
          end
        end
      end
    end
  end
end
