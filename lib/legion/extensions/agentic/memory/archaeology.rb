# frozen_string_literal: true

require 'securerandom'

require_relative 'archaeology/version'
require_relative 'archaeology/helpers/constants'
require_relative 'archaeology/helpers/artifact'
require_relative 'archaeology/helpers/excavation_site'
require_relative 'archaeology/helpers/archaeology_engine'
require_relative 'archaeology/runners/cognitive_archaeology'
require_relative 'archaeology/client'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Archaeology
        end
      end
    end
  end
end
