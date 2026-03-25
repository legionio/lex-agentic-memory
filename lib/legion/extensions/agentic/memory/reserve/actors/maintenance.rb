# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Reserve
          module Actors
            class Maintenance < Legion::Extensions::Actors::Every
              def runner_class = Runners::CognitiveReserve
              def runner_function = 'update_cognitive_reserve'
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
