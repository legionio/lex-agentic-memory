# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Offloading::Helpers::Constants do
  subject(:constants) { described_class }

  it 'defines MAX_ITEMS as 500' do
    expect(constants::MAX_ITEMS).to eq(500)
  end

  it 'defines MAX_STORES as 50' do
    expect(constants::MAX_STORES).to eq(50)
  end

  it 'defines DEFAULT_STORE_TRUST as 0.7' do
    expect(constants::DEFAULT_STORE_TRUST).to eq(0.7)
  end

  it 'defines TRUST_DECAY as 0.02' do
    expect(constants::TRUST_DECAY).to eq(0.02)
  end

  it 'defines TRUST_BOOST as 0.05' do
    expect(constants::TRUST_BOOST).to eq(0.05)
  end

  it 'defines RETRIEVAL_SUCCESS_THRESHOLD as 0.7' do
    expect(constants::RETRIEVAL_SUCCESS_THRESHOLD).to eq(0.7)
  end

  it 'defines ITEM_TYPES as frozen array of symbols' do
    expect(constants::ITEM_TYPES).to include(:fact, :procedure, :plan, :context, :delegation,
                                             :reminder, :calculation, :reference)
    expect(constants::ITEM_TYPES).to be_frozen
  end

  it 'defines STORE_TYPES as frozen array of symbols' do
    expect(constants::STORE_TYPES).to include(:database, :file, :agent, :tool, :memory_aid,
                                              :external_service, :notes)
    expect(constants::STORE_TYPES).to be_frozen
  end

  it 'maps high trust to :highly_trusted' do
    label = constants::TRUST_LABELS.find { |range, _| range.cover?(0.9) }&.last
    expect(label).to eq(:highly_trusted)
  end

  it 'maps moderate trust to :trusted' do
    label = constants::TRUST_LABELS.find { |range, _| range.cover?(0.7) }&.last
    expect(label).to eq(:trusted)
  end

  it 'maps low trust to :unreliable' do
    label = constants::TRUST_LABELS.find { |range, _| range.cover?(0.1) }&.last
    expect(label).to eq(:unreliable)
  end

  it 'maps high importance to :critical' do
    label = constants::IMPORTANCE_LABELS.find { |range, _| range.cover?(0.9) }&.last
    expect(label).to eq(:critical)
  end

  it 'maps high offloading ratio to :heavily_offloaded' do
    label = constants::OFFLOAD_LABELS.find { |range, _| range.cover?(0.9) }&.last
    expect(label).to eq(:heavily_offloaded)
  end

  it 'maps low offloading ratio to :self_reliant' do
    label = constants::OFFLOAD_LABELS.find { |range, _| range.cover?(0.1) }&.last
    expect(label).to eq(:self_reliant)
  end
end
