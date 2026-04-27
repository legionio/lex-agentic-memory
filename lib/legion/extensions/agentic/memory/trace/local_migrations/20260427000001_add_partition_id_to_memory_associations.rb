# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:memory_associations) do
      add_column :partition_id, String
      add_index :partition_id
    end

    run <<~SQL
      UPDATE memory_associations
      SET partition_id = (
        SELECT memory_traces.partition_id
        FROM memory_traces
        WHERE memory_traces.trace_id = memory_associations.trace_id_a
      )
      WHERE partition_id IS NULL
    SQL
  end

  down do
    alter_table(:memory_associations) do
      drop_index :partition_id
      drop_column :partition_id
    end
  end
end
