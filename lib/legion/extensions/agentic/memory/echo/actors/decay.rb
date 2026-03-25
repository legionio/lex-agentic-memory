# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Echo
          module Actors
            class Decay < Legion::Extensions::Actors::Every
              def runner_class = Runners::CognitiveEcho
              def runner_function = 'decay_all'
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
