# frozen_string_literal: true

require 'legion/extensions/agentic/memory/source_monitoring/helpers/constants'
require 'legion/extensions/agentic/memory/source_monitoring/helpers/source_record'
require 'legion/extensions/agentic/memory/source_monitoring/helpers/source_tracker'
require 'legion/extensions/agentic/memory/source_monitoring/runners/source_monitoring'

module Legion
  module Extensions
    module Agentic
      module Memory
        module SourceMonitoring
          class Client
            include Runners::SourceMonitoring

            def initialize(tracker: nil, **)
              @tracker = tracker || Helpers::SourceTracker.new
            end

            private

            attr_reader :tracker
          end
        end
      end
    end
  end
end
