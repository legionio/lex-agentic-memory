# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Paleontology
          class Client
            include Runners::CognitivePaleontology

            def initialize(engine: nil)
              @default_engine = engine || Helpers::PaleontologyEngine.new
            end
          end
        end
      end
    end
  end
end
