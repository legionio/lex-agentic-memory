# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Memory::Diary::Helpers::Constants do
  it 'defines TABLE_NAME' do
    expect(described_class::TABLE_NAME).to eq(:memory_diary_entries)
  end

  it 'defines DEFAULT_LIMIT' do
    expect(described_class::DEFAULT_LIMIT).to eq(20)
  end

  it 'defines MAX_LIMIT' do
    expect(described_class::MAX_LIMIT).to eq(200)
  end

  it 'defines MAX_CONTENT_SIZE' do
    expect(described_class::MAX_CONTENT_SIZE).to eq(65_536)
  end
end
