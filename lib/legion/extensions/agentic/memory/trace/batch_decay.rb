# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Trace
          module BatchDecay
            DEFAULTS = {
              rate:           0.999,
              min_confidence: 0.01,
              interval_hours: 1
            }.freeze

            class << self
              def apply!(agent_id: nil, rate: DEFAULTS[:rate], min_confidence: DEFAULTS[:min_confidence])
                return { updated: 0, evicted: 0 } unless db_ready?

                conn = Legion::Data.connection
                ds = conn[PersistentStore::TABLE]
                ds = ds.where(agent_id: agent_id) if agent_id

                updated = ds.where { confidence > min_confidence }
                            .update(confidence: Sequel[:confidence] * rate)

                evicted = ds.where { confidence <= min_confidence }.delete

                { updated: updated, evicted: evicted }
              end

              private

              def db_ready?
                defined?(Legion::Data) && Legion::Data.connection&.table_exists?(PersistentStore::TABLE)
              rescue StandardError
                false
              end
            end
          end
        end
      end
    end
  end
end
