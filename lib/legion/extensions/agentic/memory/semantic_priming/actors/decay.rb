# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module SemanticPriming
          module Actors
            class Decay < Legion::Extensions::Actors::Every
              def runner_class = Runners::SemanticPriming
              def runner_function = 'decay'
              def time = 30
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
