# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Nostalgia::Client do
  subject(:client) { described_class.new }

  describe '#initialize' do
    it 'creates a client with a nostalgia engine' do
      expect(client).to respond_to(:store_memory)
    end

    it 'accepts an injected engine' do
      engine = Legion::Extensions::Agentic::Memory::Nostalgia::Helpers::NostalgiaEngine.new
      c = described_class.new(engine: engine)
      c.store_memory(content: 'shared memory')
      expect(engine.memories.size).to eq(1)
    end
  end

  describe 'runner methods' do
    it 'responds to recall runner methods' do
      expect(client).to respond_to(:store_memory)
      expect(client).to respond_to(:trigger_nostalgia)
      expect(client).to respond_to(:age_memories)
      expect(client).to respond_to(:nostalgia_report)
    end

    it 'responds to analysis runner methods' do
      expect(client).to respond_to(:warmth_by_domain)
      expect(client).to respond_to(:rosy_retrospection_index)
      expect(client).to respond_to(:nostalgia_proneness)
      expect(client).to respond_to(:most_nostalgic_domains)
      expect(client).to respond_to(:bittersweet_memories)
    end
  end

  describe 'full cycle integration' do
    it 'stores memories, triggers nostalgia, and produces a report' do
      client.store_memory(content: 'first day of school', domain: :achievement, original_valence: 0.5)
      client.store_memory(content: 'childhood friend', domain: :relationship, original_valence: 0.6)
      client.store_memory(content: 'old neighborhood', domain: :place, original_valence: 0.3)

      client.age_memories
      result = client.trigger_nostalgia(trigger: 'childhood')
      expect(result[:success]).to be true

      report = client.nostalgia_report
      expect(report[:total_memories]).to eq(3)
      expect(report[:retrospection_label]).to be_a(Symbol)
      expect(report[:nostalgia_label]).to be_a(Symbol)
    end

    it 'identifies rosy and bittersweet memories correctly' do
      client.store_memory(content: 'rough but cherished time', domain: :challenge,
                          warmth: 0.75, original_valence: 0.2)

      bs = client.bittersweet_memories
      expect(bs[:memories].first[:content]).to eq('rough but cherished time')

      ri = client.rosy_retrospection_index
      expect(ri[:index]).to be > 0.0
    end

    it 'warmth grows over age cycles' do
      client.store_memory(content: 'fading memory', domain: :routine, warmth: 0.3)
      initial_report = client.nostalgia_report
      5.times { client.age_memories }
      later_report = client.nostalgia_report
      expect(later_report[:nostalgia_proneness]).to be >= initial_report[:nostalgia_proneness]
    end
  end
end
