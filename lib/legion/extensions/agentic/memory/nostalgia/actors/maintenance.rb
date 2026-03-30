# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Nostalgia
          module Actor
            class Maintenance < Legion::Extensions::Actors::Every
              def runner_class = Runners::Recall
              def runner_function = 'age_memories'
              def time = 120
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
