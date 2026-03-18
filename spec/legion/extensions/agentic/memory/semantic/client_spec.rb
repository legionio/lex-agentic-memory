# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Semantic::Client do
  subject(:client) { described_class.new }

  it 'includes Runners::SemanticMemory' do
    expect(described_class.ancestors).to include(Legion::Extensions::Agentic::Memory::Semantic::Runners::SemanticMemory)
  end

  it 'supports full knowledge lifecycle' do
    # Build a taxonomy
    client.store_concept(name: :animal, domain: :biology, properties: { kingdom: :animalia })
    client.relate_concepts(source: :mammal, target: :animal, type: :is_a)
    client.relate_concepts(source: :dog, target: :mammal, type: :is_a)
    client.relate_concepts(source: :cat, target: :mammal, type: :is_a)
    client.relate_concepts(source: :dog, target: :tail, type: :has_a)

    # Query taxonomy
    expect(client.check_category(concept: :dog, category: :mammal)[:is_member]).to be true
    expect(client.find_instances(category: :mammal)[:count]).to eq(2)

    # Spreading activation
    activated = client.activate_spread(seed: :dog)
    expect(activated[:activated]).to have_key(:dog)

    # Retrieve
    concept = client.retrieve_concept(name: :dog)
    expect(concept[:found]).to be true

    # Tick
    client.update_semantic_memory
    stats = client.semantic_memory_stats
    expect(stats[:stats][:concepts]).to be >= 3
  end
end
