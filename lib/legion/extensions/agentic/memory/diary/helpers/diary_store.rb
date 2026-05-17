# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Diary
          module Helpers
            class DiaryStore
              include Legion::Logging::Helper if defined?(Legion::Logging::Helper)

              def initialize(agent_id: nil)
                @agent_id = agent_id || resolve_agent_id
              end

              attr_reader :agent_id

              def write(session_id:, content:, tags: [], metadata: {})
                return nil unless db_ready?

                entry_id = SecureRandom.uuid
                now = Time.now.utc
                row = {
                  entry_id:   entry_id,
                  agent_id:   @agent_id,
                  session_id: session_id,
                  content:    sanitize(content.to_s[0...Constants::MAX_CONTENT_SIZE]),
                  tags:       tags.is_a?(Array) ? Legion::JSON.dump(tags) : '[]',
                  metadata:   metadata.is_a?(Hash) ? Legion::JSON.dump(metadata) : '{}',
                  created_at: now
                }
                db[Constants::TABLE_NAME].insert(row)
                entry_id
              rescue StandardError => e
                log_warn("write failed: #{e.message}")
                nil
              end

              def read(limit: Constants::DEFAULT_LIMIT, since: nil)
                return [] unless db_ready?

                effective_limit = [limit, Constants::MAX_LIMIT].min
                ds = scoped_ds.order(Sequel.asc(:created_at)).limit(effective_limit)
                ds = ds.where { created_at >= since } if since
                ds.all.map { |row| deserialize(row) }
              rescue StandardError => e
                log_warn("read failed: #{e.message}")
                []
              end

              def search(query:, limit: Constants::DEFAULT_LIMIT)
                return [] unless db_ready?
                return [] if query.nil? || query.strip.empty?

                effective_limit = [limit, Constants::MAX_LIMIT].min
                ds = scoped_ds
                     .where(Sequel.like(:content, "%#{sanitize(query)}%"))
                     .order(Sequel.desc(:created_at))
                     .limit(effective_limit)
                ds.all.map { |row| deserialize(row) }
              rescue StandardError => e
                log_warn("search failed: #{e.message}")
                []
              end

              def get(entry_id)
                return nil unless db_ready?

                row = scoped_ds.where(entry_id: entry_id).first
                row ? deserialize(row) : nil
              rescue StandardError => e
                log_warn("get failed: #{e.message}")
                nil
              end

              def delete(entry_id)
                return false unless db_ready?

                scoped_ds.where(entry_id: entry_id).delete
                true
              rescue StandardError => e
                log_warn("delete failed: #{e.message}")
                false
              end

              def count
                return 0 unless db_ready?

                scoped_ds.count
              rescue StandardError => e
                log_warn("count failed: #{e.message}")
                0
              end

              def db_ready?
                defined?(Legion::Data::Local) &&
                  Legion::Data::Local.respond_to?(:connected?) &&
                  Legion::Data::Local.connected? &&
                  Legion::Data::Local.connection&.table_exists?(Constants::TABLE_NAME)
              rescue StandardError => e
                log_warn("db_ready?: #{e.message}")
                false
              end

              private

              def db
                Legion::Data::Local.connection
              end

              def scoped_ds
                db[Constants::TABLE_NAME].where(agent_id: @agent_id)
              end

              def resolve_agent_id
                Legion::Settings.dig(:agent, :id) || 'default'
              rescue StandardError => e
                log_warn("resolve_agent_id: #{e.message}")
                'default'
              end

              def deserialize(row)
                {
                  entry_id:   row[:entry_id],
                  agent_id:   row[:agent_id],
                  session_id: row[:session_id],
                  content:    row[:content],
                  tags:       parse_json_array(row[:tags]),
                  metadata:   parse_json_hash(row[:metadata]),
                  created_at: row[:created_at]
                }
              end

              def parse_json_array(raw)
                return [] if raw.nil? || raw.to_s.strip.empty?

                result = Legion::JSON.load(raw)
                result.is_a?(Array) ? result : []
              rescue StandardError => e
                log_warn("parse_json_array: #{e.message}")
                []
              end

              def parse_json_hash(raw)
                return {} if raw.nil? || raw.to_s.strip.empty?

                result = Legion::JSON.load(raw)
                result.is_a?(Hash) ? result : {}
              rescue StandardError => e
                log_warn("parse_json_hash: #{e.message}")
                {}
              end

              def sanitize(value)
                return value unless value.is_a?(String)

                value.delete("\x00")
              end

              def log_warn(message)
                log.warn "[diary] #{message}"
              end
            end
          end
        end
      end
    end
  end
end
