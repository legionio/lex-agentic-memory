# frozen_string_literal: true

require 'securerandom'

require_relative 'paleontology/version'
require_relative 'paleontology/helpers/constants'
require_relative 'paleontology/helpers/fossil'
require_relative 'paleontology/helpers/excavation'
require_relative 'paleontology/helpers/paleontology_engine'
require_relative 'paleontology/runners/cognitive_paleontology'
require_relative 'paleontology/client'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Paleontology
        end
      end
    end
  end
end
