# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Hologram
          class Client
            include Runners::CognitiveHologram

            def initialize(engine: nil, **)
              @default_engine = engine || Helpers::HologramEngine.new
            end

            private

            attr_reader :default_engine
          end
        end
      end
    end
  end
end
