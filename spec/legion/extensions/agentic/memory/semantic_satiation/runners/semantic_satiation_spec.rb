# frozen_string_literal: true

require 'legion/extensions/agentic/memory/semantic_satiation/client'

RSpec.describe Legion::Extensions::Agentic::Memory::SemanticSatiation::Runners::SemanticSatiation do
  let(:client) { Legion::Extensions::Agentic::Memory::SemanticSatiation::Client.new }

  describe '#expose' do
    it 'returns a hash with fluency key' do
      result = client.expose(label: 'banana')
      expect(result[:fluency]).to be_a(Float)
    end

    it 'reduces fluency on repeated exposure' do
      client.expose(label: 'banana')
      result = client.expose(label: 'banana')
      expect(result[:fluency]).to be < 1.0
    end

    it 'uses default domain :general' do
      result = client.expose(label: 'banana')
      expect(result[:domain]).to eq(:general)
    end

    it 'accepts explicit domain' do
      result = client.expose(label: 'apple', domain: :food)
      expect(result[:domain]).to eq(:food)
    end

    it 'includes satiated flag' do
      result = client.expose(label: 'fresh')
      expect(result).to have_key(:satiated)
    end
  end

  describe '#register' do
    it 'returns a hash with id key' do
      result = client.register(label: 'oak')
      expect(result[:id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'includes label in result' do
      result = client.register(label: 'maple')
      expect(result[:label]).to eq('maple')
    end

    it 'assigns domain' do
      result = client.register(label: 'pine', domain: :nature)
      expect(result[:domain]).to eq(:nature)
    end
  end

  describe '#expose_by_id' do
    it 'exposes a registered concept by id' do
      registered = client.register(label: 'cedar')
      result = client.expose_by_id(concept_id: registered[:id])
      expect(result[:fluency]).to be < 1.0
    end

    it 'returns error for unknown concept_id' do
      result = client.expose_by_id(concept_id: 'no-such-id')
      expect(result[:error]).to eq(:not_found)
    end
  end

  describe '#recover' do
    it 'returns recovered count' do
      client.expose(label: 'worn')
      result = client.recover
      expect(result[:recovered]).to eq(1)
    end

    it 'accepts custom amount kwarg without error' do
      client.expose(label: 'test')
      expect { client.recover(amount: 0.1) }.not_to raise_error
    end
  end

  describe '#satiation_status' do
    it 'returns concept_count' do
      client.expose(label: 'word1')
      client.expose(label: 'word2')
      result = client.satiation_status
      expect(result[:concept_count]).to eq(2)
    end

    it 'includes satiated_count' do
      result = client.satiation_status
      expect(result).to have_key(:satiated_count)
    end

    it 'includes novelty_report' do
      result = client.satiation_status
      expect(result).to have_key(:novelty_report)
    end
  end

  describe '#domain_satiation' do
    it 'returns avg_fluency for domain' do
      client.expose(label: 'cat', domain: :animals)
      result = client.domain_satiation(domain: :animals)
      expect(result[:avg_fluency]).to be_a(Float)
    end

    it 'includes domain in result' do
      result = client.domain_satiation(domain: :animals)
      expect(result[:domain]).to eq(:animals)
    end

    it 'returns 0.0 for unknown domain' do
      result = client.domain_satiation(domain: :unknown)
      expect(result[:avg_fluency]).to eq(0.0)
    end
  end

  describe '#most_exposed' do
    it 'returns concepts array' do
      client.expose(label: 'a')
      result = client.most_exposed
      expect(result[:concepts]).to be_an(Array)
    end

    it 'returns count' do
      client.expose(label: 'b')
      result = client.most_exposed
      expect(result[:count]).to eq(1)
    end

    it 'respects limit parameter' do
      5.times { |i| client.expose(label: "w#{i}") }
      result = client.most_exposed(limit: 3)
      expect(result[:concepts].size).to eq(3)
    end
  end

  describe '#freshest_concepts' do
    it 'returns concepts array' do
      client.register(label: 'fresh')
      result = client.freshest_concepts
      expect(result[:concepts]).to be_an(Array)
    end

    it 'respects limit parameter' do
      5.times { |i| client.register(label: "f#{i}") }
      result = client.freshest_concepts(limit: 2)
      expect(result[:concepts].size).to eq(2)
    end
  end

  describe '#novelty_report' do
    it 'returns distribution hash' do
      client.register(label: 'new_concept')
      result = client.novelty_report
      expect(result[:distribution]).to be_a(Hash)
    end

    it 'returns total count' do
      client.register(label: 'another')
      result = client.novelty_report
      expect(result[:total]).to eq(1)
    end
  end

  describe '#prune_saturated' do
    it 'returns removed count' do
      result = client.prune_saturated
      expect(result[:removed]).to be_a(Integer)
    end

    it 'returns 0 when no saturated concepts' do
      client.register(label: 'healthy')
      result = client.prune_saturated
      expect(result[:removed]).to eq(0)
    end
  end
end
