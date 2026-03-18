# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:memory_associations) do
      primary_key :id
      String :trace_id_a, null: false, index: true
      String :trace_id_b, null: false, index: true
      Integer :coactivation_count, null: false, default: 1
      unique %i[trace_id_a trace_id_b]
    end
  end
end
