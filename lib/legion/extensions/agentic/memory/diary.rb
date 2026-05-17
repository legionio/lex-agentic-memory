# frozen_string_literal: true

require 'legion/extensions/agentic/memory/diary/version'
require 'legion/extensions/agentic/memory/diary/helpers/constants'
require 'legion/extensions/agentic/memory/diary/helpers/diary_store'
require 'legion/extensions/agentic/memory/diary/runners/diary'
require 'legion/extensions/agentic/memory/diary/client'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Diary
          class << self
            def write(session_id:, content:, agent_id: nil, tags: [], metadata: {})
              store = Helpers::DiaryStore.new(agent_id: agent_id)
              store.write(session_id: session_id, content: content, tags: tags, metadata: metadata)
            end

            def read(agent_id: nil, limit: Helpers::Constants::DEFAULT_LIMIT, since: nil)
              store = Helpers::DiaryStore.new(agent_id: agent_id)
              store.read(limit: limit, since: since)
            end

            def search(query:, agent_id: nil, limit: Helpers::Constants::DEFAULT_LIMIT)
              store = Helpers::DiaryStore.new(agent_id: agent_id)
              store.search(query: query, limit: limit)
            end
          end
        end
      end
    end
  end

  if defined?(Legion::Data::Local)
    Legion::Data::Local.register_migrations(
      name: :diary,
      path: File.join(__dir__, 'diary', 'local_migrations')
    )
  end
end
