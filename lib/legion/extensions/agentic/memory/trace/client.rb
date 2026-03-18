# frozen_string_literal: true

require 'legion/extensions/agentic/memory/trace/helpers/trace'
require 'legion/extensions/agentic/memory/trace/helpers/decay'
require 'legion/extensions/agentic/memory/trace/helpers/store'
require 'legion/extensions/agentic/memory/trace/runners/traces'
require 'legion/extensions/agentic/memory/trace/runners/consolidation'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Trace
          class Client
            include Legion::Extensions::Agentic::Memory::Trace::Runners::Traces
            include Legion::Extensions::Agentic::Memory::Trace::Runners::Consolidation

            attr_reader :store

            def initialize(store: nil, **)
              @default_store = store || Legion::Extensions::Agentic::Memory::Trace.shared_store
            end

            private

            attr_reader :default_store
          end
        end
      end
    end
  end
end
