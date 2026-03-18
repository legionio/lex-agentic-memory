# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module EchoChamber
          class Client
            include Runners::CognitiveEchoChamber

            def initialize(engine: nil)
              @default_engine = engine || Helpers::ChamberEngine.new
            end
          end
        end
      end
    end
  end
end
