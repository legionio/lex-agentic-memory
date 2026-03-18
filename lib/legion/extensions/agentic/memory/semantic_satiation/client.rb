# frozen_string_literal: true

require 'legion/extensions/agentic/memory/semantic_satiation/helpers/constants'
require 'legion/extensions/agentic/memory/semantic_satiation/helpers/concept'
require 'legion/extensions/agentic/memory/semantic_satiation/helpers/satiation_engine'
require 'legion/extensions/agentic/memory/semantic_satiation/runners/semantic_satiation'

module Legion
  module Extensions
    module Agentic
      module Memory
        module SemanticSatiation
          class Client
            include Runners::SemanticSatiation

            def initialize(**)
              @satiation_engine = Helpers::SatiationEngine.new
            end

            private

            attr_reader :satiation_engine
          end
        end
      end
    end
  end
end
