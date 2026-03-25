# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Archaeology
          module Actors
            class Decay < Legion::Extensions::Actors::Every
              def runner_class = Runners::CognitiveArchaeology
              def runner_function = 'decay_all'
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
