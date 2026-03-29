# frozen_string_literal: true

require_relative 'memory/version'
require_relative 'memory/archaeology'
require_relative 'memory/paleontology'
require_relative 'memory/palimpsest'
require_relative 'memory/compression'
require_relative 'memory/hologram'
require_relative 'memory/offloading'
require_relative 'memory/nostalgia'
require_relative 'memory/echo'
require_relative 'memory/echo_chamber'
require_relative 'memory/immune_memory'
require_relative 'memory/reserve'
require_relative 'memory/trace'
require_relative 'memory/episodic'
require_relative 'memory/semantic'
require_relative 'memory/semantic_priming'
require_relative 'memory/semantic_satiation'
require_relative 'memory/source_monitoring'
require_relative 'memory/transfer'

module Legion
  module Extensions
    module Agentic
      module Memory
        extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core

        def self.remote_invocable?
          false
        end
      end
    end
  end
end
