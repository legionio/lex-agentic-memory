# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module SemanticSatiation
          module Actor
            class Recovery < Legion::Extensions::Actors::Every
              def runner_class = Runners::SemanticSatiation
              def runner_function = 'recover'
              def time = 60
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
