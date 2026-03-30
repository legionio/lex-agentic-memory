# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Trace
          class PersistentStore
            TABLE = :memory_traces

            def initialize(agent_id:)
              @agent_id = agent_id
            end

            def write(trace_type:, content:, associations: {}, confidence: 1.0)
              return nil unless db_ready?

              Legion::Data.connection[TABLE].insert(
                agent_id:     @agent_id,
                trace_type:   trace_type.to_s,
                content:      content.is_a?(String) ? content : json_dump(content),
                associations: json_dump(associations),
                confidence:   confidence,
                created_at:   Time.now,
                accessed_at:  Time.now
              )
            end

            def read(trace_type: nil, limit: 50, min_confidence: 0.0)
              return [] unless db_ready?

              ds = Legion::Data.connection[TABLE].where(agent_id: @agent_id)
              ds = ds.where(trace_type: trace_type.to_s) if trace_type
              ds = ds.where { confidence >= min_confidence }
              ds.order(Sequel.desc(:accessed_at)).limit(limit).all
            end

            def touch(id)
              return unless db_ready?

              Legion::Data.connection[TABLE]
                          .where(id: id, agent_id: @agent_id)
                          .update(accessed_at: Time.now)
            end

            def count
              return 0 unless db_ready?

              Legion::Data.connection[TABLE].where(agent_id: @agent_id).count
            end

            def total_bytes
              return 0 unless db_ready?

              Legion::Data.connection[TABLE]
                          .where(agent_id: @agent_id)
                          .sum(Sequel.function(:length, :content)) || 0
            end

            def delete_lowest_confidence(count: 1)
              return 0 unless db_ready?

              ids = Legion::Data.connection[TABLE]
                                .where(agent_id: @agent_id)
                                .order(:confidence)
                                .limit(count)
                                .select(:id)
              Legion::Data.connection[TABLE].where(id: ids).delete
            end

            def delete_least_recently_used(count: 1)
              return 0 unless db_ready?

              ids = Legion::Data.connection[TABLE]
                                .where(agent_id: @agent_id)
                                .order(:accessed_at)
                                .limit(count)
                                .select(:id)
              Legion::Data.connection[TABLE].where(id: ids).delete
            end

            private

            def db_ready?
              defined?(Legion::Data) && Legion::Data.connection&.table_exists?(TABLE)
            rescue StandardError => _e
              false
            end
          end
        end
      end
    end
  end
end
