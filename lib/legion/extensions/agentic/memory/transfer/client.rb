# frozen_string_literal: true

require 'legion/extensions/agentic/memory/transfer/helpers/constants'
require 'legion/extensions/agentic/memory/transfer/helpers/domain_knowledge'
require 'legion/extensions/agentic/memory/transfer/helpers/transfer_engine'
require 'legion/extensions/agentic/memory/transfer/runners/transfer_learning'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Transfer
          class Client
            include Runners::TransferLearning

            def initialize(**)
              @transfer_engine = Helpers::TransferEngine.new
            end

            private

            attr_reader :transfer_engine
          end
        end
      end
    end
  end
end
