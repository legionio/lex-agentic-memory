# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Hologram do
  it 'defines a VERSION constant' do
    expect(described_class::VERSION).to eq('0.1.0')
  end

  it 'defines the Helpers module' do
    expect(described_class).to be_const_defined(:Helpers)
  end

  it 'defines the Runners module' do
    expect(described_class).to be_const_defined(:Runners)
  end

  it 'defines the Client class' do
    expect(described_class).to be_const_defined(:Client)
  end

  it 'defines Helpers::Constants' do
    expect(described_class::Helpers).to be_const_defined(:Constants)
  end

  it 'defines Helpers::HolographicFragment' do
    expect(described_class::Helpers).to be_const_defined(:HolographicFragment)
  end

  it 'defines Helpers::Hologram' do
    expect(described_class::Helpers).to be_const_defined(:Hologram)
  end

  it 'defines Helpers::HologramEngine' do
    expect(described_class::Helpers).to be_const_defined(:HologramEngine)
  end

  it 'defines Runners::CognitiveHologram' do
    expect(described_class::Runners).to be_const_defined(:CognitiveHologram)
  end
end
