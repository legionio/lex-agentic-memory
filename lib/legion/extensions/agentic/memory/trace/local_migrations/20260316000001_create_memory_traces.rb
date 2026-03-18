# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:memory_traces) do
      primary_key :id
      String :trace_id, null: false, unique: true, index: true
      String :trace_type, null: false, index: true
      String :content, text: true, null: false
      Float :strength, null: false, default: 1.0
      Float :peak_strength, null: false, default: 1.0
      Float :base_decay_rate, null: false, default: 0.02
      String :emotional_valence, text: true
      Float :emotional_intensity, default: 0.0
      String :domain_tags, text: true
      String :origin, default: 'direct_experience'
      DateTime :created_at, null: false
      DateTime :last_reinforced
      DateTime :last_decayed
      Integer :reinforcement_count, default: 0
      Float :confidence, default: 0.5
      String :storage_tier, default: 'hot', index: true
      String :partition_id, index: true
      String :associated_traces, text: true
      String :parent_id
      String :child_ids, text: true
      TrueClass :unresolved, default: false, index: true
      TrueClass :consolidation_candidate, default: false
    end
  end
end
