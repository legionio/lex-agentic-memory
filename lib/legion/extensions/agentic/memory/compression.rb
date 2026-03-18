# frozen_string_literal: true

require_relative 'compression/version'
require_relative 'compression/helpers/constants'
require_relative 'compression/helpers/information_chunk'
require_relative 'compression/helpers/compression_engine'
require_relative 'compression/runners/cognitive_compression'
require_relative 'compression/client'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Compression
        end
      end
    end
  end
end
