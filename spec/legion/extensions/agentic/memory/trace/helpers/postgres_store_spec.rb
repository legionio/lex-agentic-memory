# frozen_string_literal: true

require 'spec_helper'
require 'sequel'
require 'json'

RSpec.describe Legion::Extensions::Agentic::Memory::Trace::Helpers::PostgresStore do
  # Build an in-memory SQLite database that mirrors the shared memory_traces +
  # memory_associations tables so all Sequel queries run without a real Postgres.
  let(:db) do
    d = Sequel.sqlite
    d.create_table(:memory_traces) do
      primary_key :id
      String  :trace_id, size: 36, null: false, unique: true
      String  :agent_id, size: 64, null: false, default: 'test-agent'
      String  :tenant_id, size: 64
      String  :trace_type, null: false
      String  :content, text: true, null: false
      Float   :significance, default: 0.5
      Float   :confidence, default: 0.5
      String  :associations, text: true
      String  :domain_tags, text: true
      Float   :strength, default: 1.0
      Float   :peak_strength, default: 1.0
      Float   :base_decay_rate, default: 0.02
      Float   :emotional_valence, default: 0.0
      Float   :emotional_intensity, default: 0.0
      String  :origin
      String  :source_agent_id
      String  :storage_tier, default: 'hot'
      DateTime :last_reinforced
      DateTime :last_decayed
      Integer :reinforcement_count, default: 0
      TrueClass :unresolved, default: false
      TrueClass :consolidation_candidate, default: false
      String  :parent_trace_id, size: 36
      String  :encryption_key_id
      String  :partition_id
      DateTime :created_at
      DateTime :accessed_at
    end
    d.create_table(:memory_associations) do
      primary_key :id
      String  :trace_id_a, size: 36, null: false
      String  :trace_id_b, size: 36, null: false
      Integer :coactivation_count, default: 1, null: false
      TrueClass :linked, default: false, null: false
      String :tenant_id, size: 64
      DateTime :created_at
      DateTime :updated_at
      unique %i[trace_id_a trace_id_b]
    end
    d
  end

  let(:tenant_id) { 'test-tenant' }
  let(:store) { described_class.new(tenant_id: tenant_id) }
  let(:trace_helper) { Legion::Extensions::Agentic::Memory::Trace::Helpers::Trace }

  let(:semantic_trace) do
    trace_helper.new_trace(
      type:            :semantic,
      content_payload: { fact: 'ruby is great' },
      domain_tags:     ['programming']
    )
  end

  let(:episodic_trace) do
    trace_helper.new_trace(
      type:            :episodic,
      content_payload: { event: 'meeting' },
      domain_tags:     ['work']
    )
  end

  let(:firmware_trace) do
    trace_helper.new_trace(
      type:            :firmware,
      content_payload: { directive_text: 'protect' }
    )
  end

  before do
    allow(Legion::Data).to receive(:respond_to?).with(:connection).and_return(true)
    allow(Legion::Data).to receive(:connection).and_return(db)
    # SQLite adapter_scheme is :sqlite — postgres_available? checks for :postgres/:mysql2,
    # but PostgresStore itself only calls db_ready? which just needs the tables to exist.
    allow(db).to receive(:adapter_scheme).and_return(:sqlite)
  end

  # --- db_ready? ---

  describe '#db_ready?' do
    it 'returns true when Legion::Data is connected and both tables exist' do
      expect(store.db_ready?).to be true
    end

    it 'returns false when memory_traces does not exist' do
      db.drop_table(:memory_traces)
      expect(store.db_ready?).to be false
    end

    it 'returns false when memory_associations does not exist' do
      db.drop_table(:memory_associations)
      expect(store.db_ready?).to be false
    end

    it 'returns false when Legion::Data.connection raises' do
      allow(Legion::Data).to receive(:connection).and_raise(StandardError, 'no db')
      expect(store.db_ready?).to be false
    end
  end

  # --- store insert_conflict syntax ---

  describe '#store insert_conflict syntax' do
    it 'calls insert_conflict with target: :trace_id (not :replace symbol)' do
      ds = double('dataset')
      allow(db).to receive(:[]).with(:memory_traces).and_return(ds)
      allow(ds).to receive(:where).and_return(ds)
      allow(ds).to receive(:insert_conflict).and_return(ds)
      allow(ds).to receive(:insert)

      store.store(semantic_trace)

      expect(ds).to have_received(:insert_conflict)
        .with(hash_including(target: :trace_id))
    end
  end

  # --- store agent_id population ---

  describe '#store agent_id population' do
    it 'writes agent_id to the database row' do
      store.store(semantic_trace)
      row = db[:memory_traces].where(trace_id: semantic_trace[:trace_id]).first
      expect(row[:agent_id]).not_to be_nil
    end

    it 'uses the resolved agent_id from settings' do
      custom_store = described_class.new(tenant_id: tenant_id, agent_id: 'my-agent')
      custom_store.store(semantic_trace)
      row = db[:memory_traces].where(trace_id: semantic_trace[:trace_id]).first
      expect(row[:agent_id]).to eq('my-agent')
    end
  end

  # --- store + retrieve ---

  describe '#store and #retrieve' do
    it 'stores a trace and retrieves it by trace_id' do
      store.store(semantic_trace)
      result = store.retrieve(semantic_trace[:trace_id])
      expect(result).not_to be_nil
      expect(result[:trace_type]).to eq(:semantic)
      expect(result[:trace_id]).to eq(semantic_trace[:trace_id])
    end

    it 'returns nil for an unknown trace_id' do
      expect(store.retrieve('nonexistent-uuid')).to be_nil
    end

    it 'returns the trace_id on success' do
      tid = store.store(semantic_trace)
      expect(tid).to eq(semantic_trace[:trace_id])
    end

    it 'upserts on duplicate trace_id (second store overwrites)' do
      store.store(semantic_trace)
      updated = semantic_trace.merge(strength: 0.99)
      store.store(updated)
      result = store.retrieve(semantic_trace[:trace_id])
      expect(result[:strength]).to be_within(0.001).of(0.99)
    end

    it 'scopes retrieve to the correct tenant' do
      store.store(semantic_trace)
      other_store = described_class.new(tenant_id: 'other-tenant')
      expect(other_store.retrieve(semantic_trace[:trace_id])).to be_nil
    end

    it 'scopes retrieve to the correct agent within the same tenant' do
      store.store(semantic_trace)
      other_store = described_class.new(tenant_id: tenant_id, agent_id: 'other-agent')
      expect(other_store.retrieve(semantic_trace[:trace_id])).to be_nil
    end

    it 'returns nil when db not ready' do
      db.drop_table(:memory_traces)
      expect(store.retrieve(semantic_trace[:trace_id])).to be_nil
    end
  end

  # --- null byte sanitization ---

  describe 'null byte sanitization' do
    it 'strips null bytes from string content and stores successfully' do
      trace = trace_helper.new_trace(type: :episodic, content_payload: "hello\x00world")
      result = store.store(trace)
      expect(result).not_to be_nil

      retrieved = store.retrieve(trace[:trace_id])
      expect(retrieved[:content_payload]).to eq('helloworld')
    end

    it 'strips null bytes from hash content payloads' do
      trace = trace_helper.new_trace(type: :episodic, content_payload: { text: "has\x00null" })
      result = store.store(trace)
      expect(result).not_to be_nil

      row = db[:memory_traces].where(trace_id: trace[:trace_id]).first
      expect(row[:content]).not_to include("\x00")
    end

    it 'strips null bytes from domain_tags' do
      trace = trace_helper.new_trace(type: :episodic, content_payload: 'clean', domain_tags: ["tag\x00bad"])
      store.store(trace)

      row = db[:memory_traces].where(trace_id: trace[:trace_id]).first
      expect(row[:domain_tags]).not_to include("\x00")
    end

    it 'stores cleanly when no null bytes are present' do
      trace = trace_helper.new_trace(type: :episodic, content_payload: 'no nulls here')
      result = store.store(trace)
      expect(result).not_to be_nil

      retrieved = store.retrieve(trace[:trace_id])
      expect(retrieved[:content_payload]).to eq('no nulls here')
    end

    it 'strips null bytes during partial update' do
      store.store(semantic_trace)
      store.update(semantic_trace[:trace_id], content_payload: { text: "up\x00dated" })

      row = db[:memory_traces].where(trace_id: semantic_trace[:trace_id]).first
      expect(row[:content]).not_to include("\x00")
    end
  end

  describe 'emotional valence normalization' do
    it 'normalizes string-backed affect fields before persisting' do
      trace = trace_helper.new_trace(type: :episodic, content_payload: { event: 'partner ping' })
      trace[:emotional_valence] = '0.7'
      trace[:emotional_intensity] = '0.9'

      store.store(trace)

      row = db[:memory_traces].where(trace_id: trace[:trace_id]).first
      expect(row[:emotional_valence]).to be_within(0.001).of(0.7)
      expect(row[:emotional_intensity]).to be_within(0.001).of(0.9)
    end
  end

  # --- retrieve_by_type ---

  describe '#retrieve_by_type' do
    before do
      store.store(semantic_trace)
      store.store(episodic_trace)
    end

    it 'returns only traces of the requested type' do
      results = store.retrieve_by_type(:semantic)
      expect(results.size).to eq(1)
      expect(results.first[:trace_type]).to eq(:semantic)
    end

    it 'filters by min_strength' do
      weak = trace_helper.new_trace(type: :semantic, content_payload: {})
      weak[:strength] = 0.1
      store.store(weak)

      results = store.retrieve_by_type(:semantic, min_strength: 0.4)
      expect(results.size).to eq(1)
    end

    it 'respects limit' do
      3.times { store.store(trace_helper.new_trace(type: :semantic, content_payload: {})) }
      results = store.retrieve_by_type(:semantic, limit: 2)
      expect(results.size).to eq(2)
    end

    it 'returns empty array when db not ready' do
      db.drop_table(:memory_traces)
      expect(store.retrieve_by_type(:semantic)).to eq([])
    end
  end

  # --- retrieve_by_domain ---

  describe '#retrieve_by_domain' do
    it 'returns traces whose domain_tags include the given tag' do
      store.store(semantic_trace)
      store.store(episodic_trace)

      results = store.retrieve_by_domain('programming')
      expect(results.size).to eq(1)
      expect(results.first[:trace_type]).to eq(:semantic)
    end

    it 'returns empty when no matches' do
      store.store(semantic_trace)
      expect(store.retrieve_by_domain('unknown_tag')).to eq([])
    end
  end

  # --- all_traces ---

  describe '#all_traces' do
    it 'returns all traces for the tenant' do
      store.store(semantic_trace)
      store.store(episodic_trace)
      expect(store.all_traces.size).to eq(2)
    end

    it 'does not include traces from another tenant' do
      store.store(semantic_trace)
      other = described_class.new(tenant_id: 'other')
      other.store(episodic_trace)
      expect(store.all_traces.size).to eq(1)
    end

    it 'does not include traces from another agent in the same tenant' do
      store.store(semantic_trace)
      other = described_class.new(tenant_id: tenant_id, agent_id: 'other-agent')
      other.store(episodic_trace)
      expect(store.all_traces.map { |trace| trace[:trace_id] }).to eq([semantic_trace[:trace_id]])
    end

    it 'returns empty array when db not ready' do
      db.drop_table(:memory_traces)
      expect(store.all_traces).to eq([])
    end
  end

  # --- delete ---

  describe '#delete' do
    it 'removes the trace so it can no longer be retrieved' do
      store.store(semantic_trace)
      store.delete(semantic_trace[:trace_id])
      expect(store.retrieve(semantic_trace[:trace_id])).to be_nil
    end

    it 'removes association rows for the deleted trace' do
      store.store(semantic_trace)
      store.store(episodic_trace)
      store.record_coactivation(semantic_trace[:trace_id], episodic_trace[:trace_id])
      store.delete(semantic_trace[:trace_id])

      expect(db[:memory_associations].where(trace_id_a: semantic_trace[:trace_id]).count).to eq(0)
      expect(db[:memory_associations].where(trace_id_b: semantic_trace[:trace_id]).count).to eq(0)
    end

    it 'does not raise when the trace does not exist' do
      expect { store.delete('ghost-uuid') }.not_to raise_error
    end
  end

  # --- update ---

  describe '#update' do
    it 'modifies fields in place' do
      store.store(semantic_trace)
      store.update(semantic_trace[:trace_id], strength: 0.77)
      result = store.retrieve(semantic_trace[:trace_id])
      expect(result[:strength]).to be_within(0.001).of(0.77)
    end

    it 'translates content_payload to the content column' do
      store.store(semantic_trace)
      store.update(semantic_trace[:trace_id], content_payload: { updated: true })
      row = db[:memory_traces].where(trace_id: semantic_trace[:trace_id]).first
      expect(row[:content]).to include('updated')
    end

    it 'does not raise when db not ready' do
      db.drop_table(:memory_traces)
      expect { store.update('any', strength: 0.5) }.not_to raise_error
    end
  end

  # --- record_coactivation ---

  describe '#record_coactivation' do
    it 'creates an association row' do
      store.record_coactivation(semantic_trace[:trace_id], episodic_trace[:trace_id])
      row = db[:memory_associations].where(
        trace_id_a: semantic_trace[:trace_id],
        trace_id_b: episodic_trace[:trace_id]
      ).first
      expect(row).not_to be_nil
      expect(row[:coactivation_count]).to eq(1)
    end

    it 'increments coactivation_count on repeated calls' do
      2.times { store.record_coactivation(semantic_trace[:trace_id], episodic_trace[:trace_id]) }
      row = db[:memory_associations].where(
        trace_id_a: semantic_trace[:trace_id],
        trace_id_b: episodic_trace[:trace_id]
      ).first
      expect(row[:coactivation_count]).to eq(2)
    end

    it 'does nothing when both IDs are the same' do
      store.record_coactivation(semantic_trace[:trace_id], semantic_trace[:trace_id])
      expect(db[:memory_associations].count).to eq(0)
    end
  end

  # --- associations_for ---

  describe '#associations_for' do
    it 'returns neighbor trace IDs (bidirectional)' do
      store.record_coactivation(semantic_trace[:trace_id], episodic_trace[:trace_id])
      neighbors = store.associations_for(semantic_trace[:trace_id])
      expect(neighbors).to include(episodic_trace[:trace_id])
    end

    it 'finds associations from the b-side as well' do
      store.record_coactivation(semantic_trace[:trace_id], episodic_trace[:trace_id])
      neighbors = store.associations_for(episodic_trace[:trace_id])
      expect(neighbors).to include(semantic_trace[:trace_id])
    end

    it 'returns empty array when no associations exist' do
      expect(store.associations_for('no-assoc-id')).to eq([])
    end
  end

  # --- walk_associations ---

  describe '#walk_associations' do
    let(:trace_a) { trace_helper.new_trace(type: :semantic, content_payload: { label: 'a' }) }
    let(:trace_b) { trace_helper.new_trace(type: :semantic, content_payload: { label: 'b' }) }
    let(:trace_c) { trace_helper.new_trace(type: :semantic, content_payload: { label: 'c' }) }
    let(:trace_d) { trace_helper.new_trace(type: :semantic, content_payload: { label: 'd' }) }

    before do
      [trace_a, trace_b, trace_c, trace_d].each { |t| store.store(t) }
      # Chain: a -> b -> c -> d
      store.record_coactivation(trace_a[:trace_id], trace_b[:trace_id])
      store.record_coactivation(trace_b[:trace_id], trace_c[:trace_id])
      store.record_coactivation(trace_c[:trace_id], trace_d[:trace_id])
    end

    it 'traverses multiple hops and returns all reachable traces' do
      results = store.walk_associations(start_id: trace_a[:trace_id])
      found_ids = results.map { |r| r[:trace_id] }
      expect(found_ids).to include(trace_b[:trace_id], trace_c[:trace_id], trace_d[:trace_id])
    end

    it 'respects max_hops' do
      results = store.walk_associations(start_id: trace_a[:trace_id], max_hops: 1)
      found_ids = results.map { |r| r[:trace_id] }
      expect(found_ids).to include(trace_b[:trace_id])
      expect(found_ids).not_to include(trace_c[:trace_id])
    end

    it 'does not include the start trace in results' do
      results = store.walk_associations(start_id: trace_a[:trace_id])
      expect(results.map { |r| r[:trace_id] }).not_to include(trace_a[:trace_id])
    end

    it 'records depth for each discovered trace' do
      results = store.walk_associations(start_id: trace_a[:trace_id])
      b_result = results.find { |r| r[:trace_id] == trace_b[:trace_id] }
      c_result = results.find { |r| r[:trace_id] == trace_c[:trace_id] }
      expect(b_result[:depth]).to eq(1)
      expect(c_result[:depth]).to eq(2)
    end

    it 'records the full traversal path' do
      results = store.walk_associations(start_id: trace_a[:trace_id])
      d_result = results.find { |r| r[:trace_id] == trace_d[:trace_id] }
      expect(d_result[:path].first).to eq(trace_a[:trace_id])
      expect(d_result[:path].last).to eq(trace_d[:trace_id])
    end

    it 'handles cycles without looping infinitely' do
      store.record_coactivation(trace_d[:trace_id], trace_a[:trace_id])
      expect { store.walk_associations(start_id: trace_a[:trace_id]) }.not_to raise_error
      results = store.walk_associations(start_id: trace_a[:trace_id])
      ids = results.map { |r| r[:trace_id] }
      expect(ids.uniq.size).to eq(ids.size)
    end

    it 'returns empty array for an unknown start_id' do
      expect(store.walk_associations(start_id: 'ghost')).to eq([])
    end

    it 'filters neighbors below min_strength' do
      db[:memory_traces].where(trace_id: trace_b[:trace_id]).update(strength: 0.01)
      results = store.walk_associations(start_id: trace_a[:trace_id], min_strength: 0.1)
      found_ids = results.map { |r| r[:trace_id] }
      expect(found_ids).not_to include(trace_b[:trace_id])
      expect(found_ids).not_to include(trace_c[:trace_id])
    end
  end

  # --- delete_lowest_confidence ---

  describe '#delete_lowest_confidence' do
    it 'removes the N traces with the lowest confidence for a given type' do
      t1 = trace_helper.new_trace(type: :semantic, content_payload: {})
      t1[:confidence] = 0.1
      t2 = trace_helper.new_trace(type: :semantic, content_payload: {})
      t2[:confidence] = 0.9
      store.store(t1)
      store.store(t2)

      store.delete_lowest_confidence(trace_type: :semantic, count: 1)

      expect(store.retrieve(t1[:trace_id])).to be_nil
      expect(store.retrieve(t2[:trace_id])).not_to be_nil
    end

    it 'does not raise when db not ready' do
      db.drop_table(:memory_traces)
      expect { store.delete_lowest_confidence(trace_type: :semantic, count: 1) }.not_to raise_error
    end
  end

  # --- delete_least_recently_used ---

  describe '#delete_least_recently_used' do
    it 'removes the N least recently reinforced traces' do
      older = trace_helper.new_trace(type: :episodic, content_payload: {})
      newer = trace_helper.new_trace(type: :episodic, content_payload: {})
      older[:last_reinforced] = Time.now.utc - 3600
      newer[:last_reinforced] = Time.now.utc

      store.store(older)
      store.store(newer)

      store.delete_least_recently_used(trace_type: :episodic, count: 1)

      expect(store.retrieve(older[:trace_id])).to be_nil
      expect(store.retrieve(newer[:trace_id])).not_to be_nil
    end

    it 'does not raise when db not ready' do
      db.drop_table(:memory_traces)
      expect { store.delete_least_recently_used(trace_type: :episodic, count: 1) }.not_to raise_error
    end
  end

  # --- firmware_traces ---

  describe '#firmware_traces' do
    it 'returns only firmware-type traces' do
      store.store(firmware_trace)
      store.store(semantic_trace)

      results = store.firmware_traces
      expect(results.size).to eq(1)
      expect(results.first[:trace_type]).to eq(:firmware)
    end
  end

  # --- flush ---

  describe '#flush' do
    it 'is a no-op and does not raise' do
      expect { store.flush }.not_to raise_error
    end

    it 'returns nil' do
      expect(store.flush).to be_nil
    end
  end

  # --- plain-text content round-trip (log spam regression) ---

  describe 'plain-text content deserialization' do
    it 'returns plain-text content as-is without logging errors' do
      trace = trace_helper.new_trace(type: :episodic, content_payload: 'It appears the service is down.')
      store.store(trace)

      expect(store).not_to receive(:log)
      result = store.retrieve(trace[:trace_id])
      expect(result[:content]).to eq('It appears the service is down.')
    end

    it 'parses JSON object content into a hash' do
      trace = trace_helper.new_trace(type: :semantic, content_payload: { fact: 'ruby' })
      store.store(trace)

      result = store.retrieve(trace[:trace_id])
      expect(result[:content]).to be_a(Hash)
    end

    it 'does not log errors when domain_tags column is nil' do
      trace = trace_helper.new_trace(type: :episodic, content_payload: 'hello')
      store.store(trace)

      db[:memory_traces].where(trace_id: trace[:trace_id]).update(domain_tags: nil)

      expect(store).not_to receive(:log)
      result = store.retrieve(trace[:trace_id])
      expect(result[:domain_tags]).to eq([])
    end

    it 'does not log errors when associations column is nil' do
      trace = trace_helper.new_trace(type: :episodic, content_payload: 'hello')
      store.store(trace)

      db[:memory_traces].where(trace_id: trace[:trace_id]).update(associations: nil)

      expect(store).not_to receive(:log)
      result = store.retrieve(trace[:trace_id])
      expect(result[:associated_traces]).to eq([])
    end

    it 'generates no ERROR log lines during a bulk read with mixed content types' do
      plain_trace = trace_helper.new_trace(type: :episodic, content_payload: 'Hello, I am plain text')
      json_trace  = trace_helper.new_trace(type: :semantic, content_payload: { fact: 'structured' })
      store.store(plain_trace)
      store.store(json_trace)

      log_double = double('log', debug: nil, info: nil, warn: nil)
      allow(store).to receive(:log).and_return(log_double)
      expect(log_double).not_to receive(:error)

      results = store.all_traces
      expect(results.size).to eq(2)
    end
  end
end
