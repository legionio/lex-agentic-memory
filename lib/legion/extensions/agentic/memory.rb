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
require_relative 'memory/consolidation'
require_relative 'memory/trace'
require_relative 'memory/episodic'
require_relative 'memory/semantic'
require_relative 'memory/semantic_priming'
require_relative 'memory/semantic_satiation'
require_relative 'memory/source_monitoring'
require_relative 'memory/transfer'
require_relative 'memory/communication_pattern'

module Legion
  module Extensions
    module Agentic
      module Memory
        extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core, false

        def self.remote_invocable?
          false
        end

        def self.mcp_tools?
          false
        end

        def self.mcp_tools_deferred?
          false
        end

        def self.transport_required?
          false
        end

        def self.handle_pre_compact_event(event)
          agent_id = event[:agent_id] || event[:agent]
          session = event[:session] || event[:transcript] || event[:messages]
          Consolidation::PreCompact.before_compact(session: session, agent_id: agent_id)
        end
      end
    end
  end
end

# Snapshot lifecycle hooks
if defined?(Legion::Events)
  settings_loaded = defined?(Legion::Settings)
  snapshot_enabled = settings_loaded ? Legion::Settings.dig(:snapshot, :enabled) : true
  if snapshot_enabled
    require 'legion/extensions/agentic/memory/trace/helpers/snapshot'

    Legion::Events.on('service.shutting_down') do
      auto_save = settings_loaded ? Legion::Settings.dig(:snapshot, :auto_save_on_shutdown) : true
      next unless auto_save

      agent_id = (settings_loaded ? Legion::Settings.dig(:agent, :id) : nil) || 'default'
      Legion::Extensions::Agentic::Memory::Trace::Helpers::Snapshot.save_snapshot(agent_id: agent_id)
    end

    Legion::Events.once('gaia.started') do
      auto_restore = settings_loaded ? Legion::Settings.dig(:snapshot, :auto_restore_on_boot) : true
      next unless auto_restore

      agent_id = (settings_loaded ? Legion::Settings.dig(:agent, :id) : nil) || 'default'
      Legion::Extensions::Agentic::Memory::Trace::Helpers::Snapshot.restore_snapshot(agent_id: agent_id)
    end
  end

  pre_compact_enabled = settings_loaded ? Legion::Settings.dig(:memory, :pre_compact, :enabled) != false : true
  if pre_compact_enabled
    %w[chat.pre_compact context.pre_compact conversation.pre_compact].each do |event_name|
      Legion::Events.on(event_name) { |event| Legion::Extensions::Agentic::Memory.handle_pre_compact_event(event) }
    end
  end
end
