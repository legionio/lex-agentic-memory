# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Palimpsest
          class Client
            include Runners::CognitivePalimpsest

            def initialize(engine: nil)
              @default_engine = engine || Helpers::PalimpsestEngine.new
            end
          end
        end
      end
    end
  end
end
