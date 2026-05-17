# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:memory_diary_entries) do
      primary_key :id
      String   :entry_id,   size: 36, null: false, unique: true
      String   :agent_id,   size: 64, null: false
      String   :session_id, size: 64
      String   :content,    text: true, null: false
      String   :tags,       text: true
      String   :metadata,   text: true
      DateTime :created_at, null: false

      index :agent_id
      index %i[agent_id created_at]
    end
  end
end
