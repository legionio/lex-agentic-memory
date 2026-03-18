# frozen_string_literal: true

require 'legion/extensions/agentic/memory/trace/version'
require 'legion/extensions/agentic/memory/trace/helpers/trace'
require 'legion/extensions/agentic/memory/trace/helpers/decay'
require 'legion/extensions/agentic/memory/trace/helpers/store'
require 'legion/extensions/agentic/memory/trace/helpers/cache_store'
require 'legion/extensions/agentic/memory/trace/helpers/error_tracer'
require 'legion/extensions/agentic/memory/trace/runners/traces'
require 'legion/extensions/agentic/memory/trace/runners/consolidation'
require 'legion/extensions/agentic/memory/trace/client'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Trace
          class << self
            # Process-wide shared store. All memory runners delegate here so that
            # traces written by one component (ErrorTracer, coldstart, tick) are
            # visible to every other component (dream cycle, cortex, predictions).
            # CacheStore adds cross-process sharing via memcached on top of this.
            def shared_store
              @shared_store ||= create_store
            end

            def reset_store!
              @shared_store = nil
            end

            private

            def create_store
              if defined?(Legion::Cache) && Legion::Cache.respond_to?(:connected?) && Legion::Cache.connected?
                Legion::Logging.debug '[memory] Using shared CacheStore (memcached)'
                Helpers::CacheStore.new
              else
                Legion::Logging.debug '[memory] Using shared in-memory Store'
                Helpers::Store.new
              end
            end
          end
        end
      end
    end

    if defined?(Legion::Data::Local)
      Legion::Data::Local.register_migrations(
        name: :memory,
        path: File.join(__dir__, 'memory', 'local_migrations')
      )
    end
  end
end
