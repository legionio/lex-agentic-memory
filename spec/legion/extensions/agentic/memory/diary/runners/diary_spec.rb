# frozen_string_literal: true

require 'spec_helper'
require 'sequel'

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

RSpec.describe Legion::Extensions::Agentic::Memory::Diary::Runners::Diary do
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

  let(:store) { Legion::Extensions::Agentic::Memory::Diary::Helpers::DiaryStore.new(agent_id: 'runner-agent') }

  let(:runner) do
    client = Legion::Extensions::Agentic::Memory::Diary::Client.new(store: store)
    client
  end

  before do
    allow(Legion::Data::Local).to receive(:respond_to?).and_call_original
    allow(Legion::Data::Local).to receive(:respond_to?).with(:connected?).and_return(true)
    allow(Legion::Data::Local).to receive(:connected?).and_return(true)
    allow(Legion::Data::Local).to receive(:connection).and_return(db)
  end

  describe '#write_diary' do
    it 'writes an entry and returns success with entry_id' do
      result = runner.write_diary(session_id: 'sess-1', content: 'test notes')
      expect(result[:success]).to be true
      expect(result[:entry_id]).to be_a(String)
    end

    it 'returns failure when store is not available' do
      allow(Legion::Data::Local).to receive(:connected?).and_return(false)
      result = runner.write_diary(session_id: 'sess-1', content: 'test')
      expect(result[:success]).to be false
    end
  end

  describe '#read_diary' do
    before do
      runner.write_diary(session_id: 'sess-1', content: 'entry one')
      runner.write_diary(session_id: 'sess-2', content: 'entry two')
    end

    it 'returns entries with count' do
      result = runner.read_diary
      expect(result[:success]).to be true
      expect(result[:count]).to eq(2)
      expect(result[:entries].size).to eq(2)
    end

    it 'respects limit' do
      result = runner.read_diary(limit: 1)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#search_diary' do
    before do
      runner.write_diary(session_id: 'sess-1', content: 'discussed caching strategy')
      runner.write_diary(session_id: 'sess-2', content: 'fixed database bug')
    end

    it 'finds entries matching query' do
      result = runner.search_diary(query: 'caching')
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
    end

    it 'returns empty for no match' do
      result = runner.search_diary(query: 'nonexistent')
      expect(result[:count]).to eq(0)
    end
  end

  describe '#diary_stats' do
    it 'returns stats for the agent diary' do
      runner.write_diary(session_id: 'sess-1', content: 'test')
      result = runner.diary_stats
      expect(result[:success]).to be true
      expect(result[:agent_id]).to eq('runner-agent')
      expect(result[:entry_count]).to eq(1)
      expect(result[:available]).to be true
    end
  end
end
