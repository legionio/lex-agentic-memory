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

# Snapshot lifecycle hooks
if defined?(Legion::Events)
  snapshot_enabled = begin
    Legion::Settings.dig(:snapshot, :enabled)
  rescue StandardError => _e
    true
  end
  if snapshot_enabled
    require 'legion/extensions/agentic/memory/trace/helpers/snapshot'

    Legion::Events.on('service.shutting_down') do
      next unless begin
        Legion::Settings.dig(:snapshot, :auto_save_on_shutdown)
      rescue StandardError => _e
        true
      end

      agent_id = begin
        Legion::Settings.dig(:agent, :id)
      rescue StandardError => _e
        nil
      end || 'default'
      Legion::Extensions::Agentic::Memory::Trace::Helpers::Snapshot.save_snapshot(agent_id: agent_id)
    end

    Legion::Events.once('gaia.started') do
      next unless begin
        Legion::Settings.dig(:snapshot, :auto_restore_on_boot)
      rescue StandardError => _e
        true
      end

      agent_id = begin
        Legion::Settings.dig(:agent, :id)
      rescue StandardError => _e
        nil
      end || 'default'
      Legion::Extensions::Agentic::Memory::Trace::Helpers::Snapshot.restore_snapshot(agent_id: agent_id)
    end
  end
end
