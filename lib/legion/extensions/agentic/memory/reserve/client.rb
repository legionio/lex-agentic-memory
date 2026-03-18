# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Reserve
          class Client
            include Runners::CognitiveReserve

            def initialize(engine: nil)
              @engine = engine
            end
          end
        end
      end
    end
  end
end
