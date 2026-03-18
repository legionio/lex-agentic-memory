# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module SourceMonitoring
          module Actors
            class Decay < Legion::Extensions::Actors::Every
              def time
                60
              end

              def use_runner?
                false
              end

              def runner_function
                :update_source_monitoring
              end

              def runner_class
                Legion::Extensions::Agentic::Memory::SourceMonitoring::Runners::SourceMonitoring
              end
            end
          end
        end
      end
    end
  end
end
