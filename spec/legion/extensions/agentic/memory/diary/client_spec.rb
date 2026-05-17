# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Memory::Diary::Client do
  let(:store) { instance_double(Legion::Extensions::Agentic::Memory::Diary::Helpers::DiaryStore) }
  let(:client) { described_class.new(store: store) }

  before do
    allow(store).to receive(:agent_id).and_return('test-agent')
    allow(store).to receive(:db_ready?).and_return(true)
    allow(store).to receive(:count).and_return(5)
  end

  it 'includes Runners::Diary' do
    expect(described_class.ancestors).to include(Legion::Extensions::Agentic::Memory::Diary::Runners::Diary)
  end

  it 'delegates write_diary to the store' do
    allow(store).to receive(:write).and_return('entry-uuid')
    result = client.write_diary(session_id: 'sess-1', content: 'notes')
    expect(result[:success]).to be true
    expect(result[:entry_id]).to eq('entry-uuid')
  end

  it 'delegates read_diary to the store' do
    allow(store).to receive(:read).and_return([{ entry_id: 'e1', content: 'test' }])
    result = client.read_diary
    expect(result[:success]).to be true
    expect(result[:count]).to eq(1)
  end

  it 'delegates search_diary to the store' do
    allow(store).to receive(:search).and_return([])
    result = client.search_diary(query: 'redis')
    expect(result[:success]).to be true
    expect(result[:count]).to eq(0)
  end

  it 'returns diary_stats' do
    result = client.diary_stats
    expect(result[:agent_id]).to eq('test-agent')
    expect(result[:entry_count]).to eq(5)
  end
end
