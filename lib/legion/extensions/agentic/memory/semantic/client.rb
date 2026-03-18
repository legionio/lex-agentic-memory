# frozen_string_literal: true

require 'legion/extensions/agentic/memory/semantic/helpers/constants'
require 'legion/extensions/agentic/memory/semantic/helpers/concept'
require 'legion/extensions/agentic/memory/semantic/helpers/knowledge_store'
require 'legion/extensions/agentic/memory/semantic/runners/semantic_memory'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Semantic
          class Client
            include Runners::SemanticMemory

            def initialize(knowledge_store: nil, **)
              @knowledge_store = knowledge_store || Helpers::KnowledgeStore.new
            end

            private

            attr_reader :knowledge_store
          end
        end
      end
    end
  end
end
