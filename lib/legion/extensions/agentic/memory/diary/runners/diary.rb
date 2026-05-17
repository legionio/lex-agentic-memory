# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Diary
          module Runners
            module Diary
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def write_diary(session_id:, content:, tags: [], metadata: {}, store: nil, **)
                s = store || diary_store
                entry_id = s.write(session_id: session_id, content: content, tags: tags, metadata: metadata)
                if entry_id
                  log.debug("[diary] wrote entry=#{entry_id} agent=#{s.agent_id} session=#{session_id}")
                  { success: true, entry_id: entry_id }
                else
                  { success: false, error: 'diary store not available' }
                end
              end

              def read_diary(limit: Helpers::Constants::DEFAULT_LIMIT, since: nil, store: nil, **)
                s = store || diary_store
                entries = s.read(limit: limit, since: since)
                log.debug("[diary] read #{entries.size} entries for agent=#{s.agent_id}")
                { success: true, entries: entries, count: entries.size }
              end

              def search_diary(query:, limit: Helpers::Constants::DEFAULT_LIMIT, store: nil, **)
                s = store || diary_store
                entries = s.search(query: query, limit: limit)
                log.debug("[diary] search query=#{query} found=#{entries.size} agent=#{s.agent_id}")
                { success: true, entries: entries, count: entries.size }
              end

              def diary_stats(store: nil, **)
                s = store || diary_store
                { success: true, agent_id: s.agent_id, entry_count: s.count, available: s.db_ready? }
              end

              private

              def diary_store
                @diary_store ||= Helpers::DiaryStore.new
              end
            end
          end
        end
      end
    end
  end
end
