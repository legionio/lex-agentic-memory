# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Compression
          module Actors
            class Maintenance < Legion::Extensions::Actors::Every
              def runner_class = Runners::CognitiveCompression
              def runner_function = 'compress_all'
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
