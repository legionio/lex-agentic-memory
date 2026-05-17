# frozen_string_literal: true

require 'spec_helper'
require 'sequel'
require 'json'

unless defined?(Legion::Data::Local)
  module Legion
    module Data
      module Local
        class << self
          attr_reader :connection

          def connected?
            !@connection.nil?
          end

          def respond_to?(method, *)
            super
          end
        end
      end
    end
  end
end

RSpec.describe Legion::Extensions::Agentic::Memory::Diary::Helpers::DiaryStore do
  let(:db) do
    d = Sequel.sqlite
    d.create_table(:memory_diary_entries) do
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
    d
  end

  let(:store) { described_class.new(agent_id: 'test-agent') }

  before do
    allow(Legion::Data::Local).to receive(:respond_to?).and_call_original
    allow(Legion::Data::Local).to receive(:respond_to?).with(:connected?).and_return(true)
    allow(Legion::Data::Local).to receive(:connected?).and_return(true)
    allow(Legion::Data::Local).to receive(:connection).and_return(db)
  end

  describe '#db_ready?' do
    it 'returns true when local DB is connected and table exists' do
      expect(store.db_ready?).to be true
    end

    it 'returns false when table does not exist' do
      db.drop_table(:memory_diary_entries)
      expect(store.db_ready?).to be false
    end

    it 'returns false when Local is not connected' do
      allow(Legion::Data::Local).to receive(:connected?).and_return(false)
      expect(store.db_ready?).to be false
    end
  end

  describe '#write' do
    it 'creates a diary entry and returns the entry_id' do
      entry_id = store.write(session_id: 'sess-1', content: 'learned about caching')
      expect(entry_id).to be_a(String)
      expect(entry_id.length).to eq(36)
    end

    it 'persists the entry to the database' do
      store.write(session_id: 'sess-1', content: 'session notes', tags: %w[decisions])
      row = db[:memory_diary_entries].first
      expect(row[:agent_id]).to eq('test-agent')
      expect(row[:session_id]).to eq('sess-1')
      expect(row[:content]).to eq('session notes')
      expect(JSON.parse(row[:tags])).to eq(['decisions'])
    end

    it 'returns nil when db is not ready' do
      allow(Legion::Data::Local).to receive(:connected?).and_return(false)
      expect(store.write(session_id: 'sess-1', content: 'test')).to be_nil
    end

    it 'strips null bytes from content' do
      store.write(session_id: 'sess-1', content: "hello\x00world")
      row = db[:memory_diary_entries].first
      expect(row[:content]).to eq('helloworld')
    end

    it 'truncates content beyond MAX_CONTENT_SIZE' do
      long_content = 'x' * 100_000
      store.write(session_id: 'sess-1', content: long_content)
      row = db[:memory_diary_entries].first
      expect(row[:content].length).to eq(65_536)
    end
  end

  describe '#read' do
    before do
      store.write(session_id: 'sess-1', content: 'first entry', tags: %w[boot])
      store.write(session_id: 'sess-2', content: 'second entry', tags: %w[work])
      store.write(session_id: 'sess-3', content: 'third entry', tags: %w[debug])
    end

    it 'returns entries in chronological order (oldest first)' do
      entries = store.read
      expect(entries.size).to eq(3)
      expect(entries.first[:content]).to eq('first entry')
      expect(entries.last[:content]).to eq('third entry')
    end

    it 'respects the limit parameter' do
      entries = store.read(limit: 2)
      expect(entries.size).to eq(2)
    end

    it 'caps limit at MAX_LIMIT' do
      entries = store.read(limit: 500)
      expect(entries.size).to eq(3)
    end

    it 'scopes to the current agent only' do
      other = described_class.new(agent_id: 'other-agent')
      other.write(session_id: 'sess-x', content: 'other agent entry')
      entries = store.read
      expect(entries.size).to eq(3)
    end

    it 'deserializes tags as an array' do
      entries = store.read(limit: 1)
      expect(entries.first[:tags]).to eq(['boot'])
    end

    it 'returns empty array when db not ready' do
      allow(Legion::Data::Local).to receive(:connected?).and_return(false)
      expect(store.read).to eq([])
    end
  end

  describe '#search' do
    before do
      store.write(session_id: 'sess-1', content: 'decided to use Redis for caching')
      store.write(session_id: 'sess-2', content: 'discussed database migration plan')
      store.write(session_id: 'sess-3', content: 'optimized Redis pool settings')
    end

    it 'returns entries matching the query' do
      entries = store.search(query: 'Redis')
      expect(entries.size).to eq(2)
    end

    it 'returns empty for no match' do
      entries = store.search(query: 'nonexistent')
      expect(entries.empty?).to be true
    end

    it 'returns empty for nil/blank query' do
      expect(store.search(query: nil)).to eq([])
      expect(store.search(query: '  ')).to eq([])
    end

    it 'scopes to current agent' do
      other = described_class.new(agent_id: 'other-agent')
      other.write(session_id: 'sess-x', content: 'Redis in other agent')
      entries = store.search(query: 'Redis')
      expect(entries.size).to eq(2)
    end
  end

  describe '#get' do
    it 'retrieves a single entry by entry_id' do
      entry_id = store.write(session_id: 'sess-1', content: 'test entry')
      entry = store.get(entry_id)
      expect(entry[:entry_id]).to eq(entry_id)
      expect(entry[:content]).to eq('test entry')
    end

    it 'returns nil for unknown entry_id' do
      expect(store.get('nonexistent')).to be_nil
    end

    it 'does not return entries from another agent' do
      entry_id = store.write(session_id: 'sess-1', content: 'mine')
      other = described_class.new(agent_id: 'other-agent')
      expect(other.get(entry_id)).to be_nil
    end
  end

  describe '#delete' do
    it 'removes the entry' do
      entry_id = store.write(session_id: 'sess-1', content: 'deletable')
      expect(store.delete(entry_id)).to be true
      expect(store.get(entry_id)).to be_nil
    end

    it 'returns false when db not ready' do
      allow(Legion::Data::Local).to receive(:connected?).and_return(false)
      expect(store.delete('any')).to be false
    end
  end

  describe '#count' do
    it 'returns the number of entries for the agent' do
      store.write(session_id: 'sess-1', content: 'one')
      store.write(session_id: 'sess-2', content: 'two')
      expect(store.count).to eq(2)
    end

    it 'does not count entries from other agents' do
      store.write(session_id: 'sess-1', content: 'mine')
      other = described_class.new(agent_id: 'other-agent')
      other.write(session_id: 'sess-x', content: 'theirs')
      expect(store.count).to eq(1)
    end
  end
end
