# frozen_string_literal: true

require 'sequel'
require 'sequel/extensions/migration'

# Minimal stub for Legion::Data::Local used in persistence specs.
# Does not require the full legion-data gem.
module Legion
  module Data
    module Local
      class << self
        attr_reader :connection

        def setup_in_memory!
          ::Sequel.extension :migration
          @connection = ::Sequel.sqlite
          @connected = true
          run_memory_migrations
        end

        def connected?
          @connected == true
        end

        def table_exists?(name)
          @connection&.table_exists?(name) || false
        end

        def reset!
          @connection&.disconnect
          @connection = nil
          @connected = false
        end

        private

        def run_memory_migrations
          migration_path = File.join(
            __dir__,
            '../lib/legion/extensions/memory/local_migrations'
          )
          ::Sequel::TimestampMigrator.new(@connection, migration_path).run
        end
      end
    end
  end
end

RSpec.describe 'lex-memory local SQLite persistence' do
  let(:store) { Legion::Extensions::Agentic::Memory::Trace::Helpers::Store.new }
  let(:trace_helper) { Legion::Extensions::Agentic::Memory::Trace::Helpers::Trace }

  let(:semantic_trace) do
    trace_helper.new_trace(
      type:            :semantic,
      content_payload: { fact: 'SQLite is persistent' },
      domain_tags:     ['storage']
    )
  end

  let(:episodic_trace) do
    trace_helper.new_trace(
      type:            :episodic,
      content_payload: { event: 'first boot' },
      domain_tags:     ['boot']
    )
  end

  before(:all) do
    Legion::Data::Local.setup_in_memory!
  end

  after(:all) do
    Legion::Data::Local.reset!
  end

  before(:each) do
    # Clear tables between examples so tests are isolated
    db = Legion::Data::Local.connection
    db[:memory_associations].delete
    db[:memory_traces].delete
    Legion::Extensions::Agentic::Memory::Trace.reset_store!
  end

  describe '#save_to_local' do
    it 'persists traces to the SQLite database' do
      store.store(semantic_trace)
      store.store(episodic_trace)
      store.save_to_local

      db = Legion::Data::Local.connection
      expect(db[:memory_traces].count).to eq(2)
    end

    it 'persists trace fields accurately' do
      store.store(semantic_trace)
      store.save_to_local

      db = Legion::Data::Local.connection
      row = db[:memory_traces].where(trace_id: semantic_trace[:trace_id]).first
      expect(row).not_to be_nil
      expect(row[:trace_type]).to eq('semantic')
      expect(row[:strength]).to eq(semantic_trace[:strength])
    end

    it 'persists associations to the SQLite database' do
      store.store(semantic_trace)
      store.store(episodic_trace)

      threshold = Legion::Extensions::Agentic::Memory::Trace::Helpers::Trace::COACTIVATION_THRESHOLD
      threshold.times { store.record_coactivation(semantic_trace[:trace_id], episodic_trace[:trace_id]) }
      store.save_to_local

      db = Legion::Data::Local.connection
      expect(db[:memory_associations].count).to be > 0
    end

    it 'updates an existing trace row on subsequent saves' do
      store.store(semantic_trace)
      store.save_to_local

      # Mutate strength directly and save again
      store.traces[semantic_trace[:trace_id]][:strength] = 0.99
      store.save_to_local

      db = Legion::Data::Local.connection
      row = db[:memory_traces].where(trace_id: semantic_trace[:trace_id]).first
      expect(row[:strength]).to eq(0.99)
      expect(db[:memory_traces].count).to eq(1)
    end

    it 'removes pruned traces from the database' do
      store.store(semantic_trace)
      store.store(episodic_trace)
      store.save_to_local

      # Prune semantic_trace from memory (simulate decay below threshold)
      store.delete(semantic_trace[:trace_id])
      store.save_to_local

      db = Legion::Data::Local.connection
      expect(db[:memory_traces].count).to eq(1)
      expect(db[:memory_traces].first[:trace_id]).to eq(episodic_trace[:trace_id])
    end

    it 'replaces association rows on each save' do
      store.store(semantic_trace)
      store.store(episodic_trace)

      threshold = Legion::Extensions::Agentic::Memory::Trace::Helpers::Trace::COACTIVATION_THRESHOLD
      threshold.times { store.record_coactivation(semantic_trace[:trace_id], episodic_trace[:trace_id]) }
      store.save_to_local

      first_count = Legion::Data::Local.connection[:memory_associations].count

      store.save_to_local

      second_count = Legion::Data::Local.connection[:memory_associations].count
      expect(second_count).to eq(first_count)
    end

    it 'is a no-op when Local is not connected' do
      allow(Legion::Data::Local).to receive(:connected?).and_return(false)
      expect { store.save_to_local }.not_to raise_error
    end
  end

  describe '#load_from_local' do
    it 'restores traces from the database into a fresh store' do
      store.store(semantic_trace)
      store.store(episodic_trace)
      store.save_to_local

      fresh = Legion::Extensions::Agentic::Memory::Trace::Helpers::Store.new
      expect(fresh.count).to eq(2)
      expect(fresh.get(semantic_trace[:trace_id])).not_to be_nil
      expect(fresh.get(episodic_trace[:trace_id])).not_to be_nil
    end

    it 'restores associations from the database into a fresh store' do
      store.store(semantic_trace)
      store.store(episodic_trace)

      threshold = Legion::Extensions::Agentic::Memory::Trace::Helpers::Trace::COACTIVATION_THRESHOLD
      threshold.times { store.record_coactivation(semantic_trace[:trace_id], episodic_trace[:trace_id]) }
      store.save_to_local

      fresh = Legion::Extensions::Agentic::Memory::Trace::Helpers::Store.new
      expect(fresh.associations[semantic_trace[:trace_id]]).not_to be_empty
    end

    it 'is a no-op when Local is not connected' do
      allow(Legion::Data::Local).to receive(:connected?).and_return(false)
      expect { store.load_from_local }.not_to raise_error
    end
  end

  describe 'round-trip: save then load' do
    it 'produces identical trace data in a fresh store' do
      store.store(semantic_trace)
      store.store(episodic_trace)
      store.save_to_local

      fresh = Legion::Extensions::Agentic::Memory::Trace::Helpers::Store.new
      restored = fresh.get(semantic_trace[:trace_id])

      expect(restored[:trace_id]).to eq(semantic_trace[:trace_id])
      expect(restored[:trace_type]).to eq(:semantic)
      expect(restored[:strength]).to eq(semantic_trace[:strength])
      expect(restored[:domain_tags]).to eq(semantic_trace[:domain_tags])
      expect(restored[:origin]).to eq(semantic_trace[:origin])
    end

    it 'restores content hash with symbol keys' do
      store.store(semantic_trace)
      store.save_to_local

      fresh = Legion::Extensions::Agentic::Memory::Trace::Helpers::Store.new
      restored = fresh.get(semantic_trace[:trace_id])
      expect(restored[:content]).to be_a(Hash)
      expect(restored[:content][:fact]).to eq('SQLite is persistent')
    end

    it 'restores domain_tags as an array' do
      store.store(semantic_trace)
      store.save_to_local

      fresh = Legion::Extensions::Agentic::Memory::Trace::Helpers::Store.new
      restored = fresh.get(semantic_trace[:trace_id])
      expect(restored[:domain_tags]).to eq(['storage'])
    end

    it 'preserves storage_tier as a symbol' do
      store.store(semantic_trace)
      store.save_to_local

      fresh = Legion::Extensions::Agentic::Memory::Trace::Helpers::Store.new
      restored = fresh.get(semantic_trace[:trace_id])
      expect(restored[:storage_tier]).to eq(:hot)
    end

    it 'preserves association coactivation counts' do
      store.store(semantic_trace)
      store.store(episodic_trace)

      threshold = Legion::Extensions::Agentic::Memory::Trace::Helpers::Trace::COACTIVATION_THRESHOLD
      threshold.times { store.record_coactivation(semantic_trace[:trace_id], episodic_trace[:trace_id]) }
      store.save_to_local

      fresh = Legion::Extensions::Agentic::Memory::Trace::Helpers::Store.new
      count = fresh.associations[semantic_trace[:trace_id]][episodic_trace[:trace_id]]
      expect(count).to eq(threshold)
    end
  end
end
