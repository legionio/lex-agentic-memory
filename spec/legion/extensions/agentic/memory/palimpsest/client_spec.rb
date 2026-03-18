# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Palimpsest::Client do
  subject(:client) { described_class.new }

  it 'full lifecycle: overwrite, peek, ghost, drift, report' do
    r1 = client.overwrite_belief(topic: 'democracy', content: 'mob rule', confidence: 0.4)
    expect(r1[:success]).to be true

    r2 = client.overwrite_belief(topic: 'democracy', content: 'representative government', confidence: 0.9)
    expect(r2[:version]).to eq(2)

    peek = client.peek_through_belief(topic: 'democracy', depth: 1)
    expect(peek[:count]).to eq(1)
    expect(peek[:layers].first[:content]).to eq('mob rule')

    ghosts = client.ghost_layers(topic: 'democracy')
    expect(ghosts[:count]).to eq(1)

    drift = client.belief_drift(topic: 'democracy')
    expect(drift[:drift]).to be_within(0.01).of(0.5)

    report = client.palimpsest_report
    expect(report[:palimpsest_count]).to eq(1)
    expect(report[:total_ghosts]).to eq(1)
  end

  it 'accepts injected engine' do
    engine = Legion::Extensions::Agentic::Memory::Palimpsest::Helpers::PalimpsestEngine.new
    c = described_class.new(engine: engine)
    c.overwrite_belief(topic: 'test', content: 'hello')
    expect(engine.palimpsests).to have_key('test')
  end

  it 'erodes and decays' do
    client.overwrite_belief(topic: 'erosion', content: 'v1', confidence: 0.8)
    result = client.erode_belief(topic: 'erosion')
    expect(result[:confidence]).to be < 0.8

    client.overwrite_belief(topic: 'erosion', content: 'v2', confidence: 0.8)
    decay_result = client.decay_all_ghosts
    expect(decay_result[:success]).to be true
  end

  it 'domain_archaeology retrieves all layers for domain' do
    client.create_palimpsest(topic: 'arch_topic', domain: :normative)
    client.overwrite_belief(topic: 'arch_topic', content: 'old norm')
    client.overwrite_belief(topic: 'arch_topic', content: 'new norm')
    result = client.domain_archaeology(domain: :normative)
    expect(result[:count]).to eq(2)
  end

  it 'most_rewritten respects limit' do
    5.times { |i| client.overwrite_belief(topic: "topic_#{i}", content: 'x') }
    result = client.most_rewritten(limit: 3)
    expect(result[:palimpsests].size).to eq(3)
  end
end
