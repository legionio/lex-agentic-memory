# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Trace
          module Actor
            class Quota < Legion::Extensions::Actors::Every
              def runner_class = Runners::Consolidation
              def runner_function = 'enforce_quota'
              def time = 300
              def use_runner? = false
              def check_subtask? = false
              def generate_task? = false
            end
          end
        end
      end
    end
  end
end
