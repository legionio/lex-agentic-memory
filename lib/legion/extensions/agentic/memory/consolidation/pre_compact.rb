# frozen_string_literal: true

require 'securerandom'
require 'time'
require 'legion/logging'
require_relative '../trace'
require_relative 'helpers/extractor'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Consolidation
          module PreCompact
            class << self
              include Legion::Logging::Helper if defined?(Legion::Logging::Helper)

              def before_compact(session:, agent_id: nil, store: nil, apollo: nil)
                summary = Helpers::Extractor.extract(session)
                saved = persist_summary(summary, session: session, agent_id: agent_id, store: store)
                promote_summary(summary, agent_id: agent_id, apollo: apollo)

                { success: true, agent_id: resolved_agent_id(agent_id), saved: saved, summary: summary }
              rescue StandardError => e
                log.warn("[memory] pre_compact save failed: #{e.message}")
                { success: false, reason: :error, message: e.message }
              end

              private

              def persist_summary(summary, session:, agent_id:, store:)
                memory_store = store || Trace.shared_store
                return 0 unless memory_store.respond_to?(:store)

                saved = 0
                summary.each do |category, entries|
                  entries.each do |entry|
                    memory_store.store(trace_for(category, entry, session: session, agent_id: agent_id))
                    saved += 1
                  end
                end
                memory_store.flush if memory_store.respond_to?(:flush)
                saved
              end

              def promote_summary(summary, agent_id:, apollo:)
                writer = apollo || (Legion::Apollo if defined?(Legion::Apollo))
                return unless writer.respond_to?(:ingest)

                summary.each do |category, entries|
                  entries.each do |entry|
                    writer.ingest(
                      content:        entry,
                      tags:           ['pre_compact', category.to_s, "agent:#{resolved_agent_id(agent_id)}"],
                      source_channel: 'memory_pre_compact'
                    )
                  end
                end
              rescue StandardError => e
                log.warn("[memory] pre_compact Apollo promotion failed: #{e.message}")
              end

              def trace_for(category, entry, session:, agent_id:)
                Trace::Helpers::Trace.new_trace(
                  type:            :semantic,
                  content_payload: {
                    category:   category,
                    text:       entry,
                    session_id: session_id(session),
                    saved_at:   Time.now.utc.iso8601
                  },
                  domain_tags:     ['pre_compact', category.to_s],
                  source_agent_id: resolved_agent_id(agent_id),
                  partition_id:    resolved_agent_id(agent_id)
                )
              end

              def session_id(session)
                return session.id if session.respond_to?(:id)
                return session[:id] if session.is_a?(Hash) && session.key?(:id)
                return session['id'] if session.is_a?(Hash)

                SecureRandom.uuid
              end

              def resolved_agent_id(agent_id)
                agent_id || (Legion::Settings.dig(:agent, :id) if defined?(Legion::Settings)) || 'default'
              rescue StandardError => e
                log.warn("[memory] pre_compact agent id resolution failed: #{e.message}")
                'default'
              end
            end
          end
        end
      end
    end
  end
end
