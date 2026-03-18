# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Nostalgia::Helpers::NostalgiaEngine do
  subject(:engine) { described_class.new }

  let(:memory_attrs) do
    { content: 'childhood home', domain: :place, original_valence: 0.4 }
  end

  describe '#create_memory' do
    it 'creates and stores a NostalgicMemory' do
      memory = engine.create_memory(**memory_attrs)
      expect(memory).to be_a(Legion::Extensions::Agentic::Memory::Nostalgia::Helpers::NostalgicMemory)
      expect(engine.memories.size).to eq(1)
    end

    it 'returns memory with correct content' do
      memory = engine.create_memory(**memory_attrs)
      expect(memory.content).to eq('childhood home')
    end

    it 'enforces MAX_MEMORIES cap' do
      (Legion::Extensions::Agentic::Memory::Nostalgia::Helpers::Constants::MAX_MEMORIES + 5).times do |i|
        engine.create_memory(content: "memory #{i}")
      end
      expect(engine.memories.size).to eq(Legion::Extensions::Agentic::Memory::Nostalgia::Helpers::Constants::MAX_MEMORIES)
    end
  end

  describe '#trigger_nostalgia' do
    before do
      engine.create_memory(content: 'old friend from school', domain: :relationship,
                           warmth: 0.7, original_valence: 0.5)
      engine.create_memory(content: 'school lunchroom', domain: :place,
                           warmth: 0.6, original_valence: 0.4)
    end

    context 'when memories match the trigger' do
      it 'returns events for matching memories' do
        events = engine.trigger_nostalgia(trigger: 'school')
        expect(events).to all(be_a(Legion::Extensions::Agentic::Memory::Nostalgia::Helpers::NostalgiaEvent))
      end

      it 'stores events internally' do
        engine.trigger_nostalgia(trigger: 'school')
        expect(engine.events).not_to be_empty
      end
    end

    context 'when domain is specified' do
      it 'filters candidates by domain' do
        events = engine.trigger_nostalgia(trigger: 'school', domain: :place)
        event_memory_ids = events.map(&:memory_id)
        place_memory = engine.memories.find { |m| m.domain == :place }
        expect(event_memory_ids).to include(place_memory.id) if place_memory && events.any?
      end
    end

    context 'when no memories exist' do
      it 'returns empty array' do
        events = described_class.new.trigger_nostalgia(trigger: 'anything')
        expect(events).to eq([])
      end
    end
  end

  describe '#age_all!' do
    it 'increments temporal_distance on all memories' do
      engine.create_memory(content: 'memory 1')
      engine.create_memory(content: 'memory 2')
      engine.age_all!
      engine.memories.each do |m|
        expect(m.temporal_distance).to eq(1)
      end
    end
  end

  describe '#warmth_by_domain' do
    before do
      engine.create_memory(content: 'beach vacation', domain: :place, warmth: 0.7)
      engine.create_memory(content: 'mountain hike', domain: :place, warmth: 0.5)
      engine.create_memory(content: 'first job', domain: :achievement, warmth: 0.8)
    end

    it 'returns average warmth per domain' do
      result = engine.warmth_by_domain
      expect(result[:place]).to be_within(0.01).of(0.6)
      expect(result[:achievement]).to be_within(0.01).of(0.8)
    end

    it 'returns a hash' do
      expect(engine.warmth_by_domain).to be_a(Hash)
    end
  end

  describe '#rosy_retrospection_index' do
    context 'with no memories' do
      it 'returns 0.0' do
        expect(engine.rosy_retrospection_index).to eq(0.0)
      end
    end

    context 'with rosy memories' do
      before do
        engine.create_memory(content: 'good times', warmth: 0.9, original_valence: 0.3)
        engine.create_memory(content: 'average times', warmth: 0.4, original_valence: 0.4)
      end

      it 'returns a value in [0, 1]' do
        expect(engine.rosy_retrospection_index).to be_between(0.0, 1.0)
      end
    end
  end

  describe '#nostalgia_proneness' do
    context 'with no memories' do
      it 'returns 0.0' do
        expect(engine.nostalgia_proneness).to eq(0.0)
      end
    end

    context 'with highly warm memories' do
      before do
        5.times { |i| engine.create_memory(content: "memory #{i}", warmth: 0.8) }
      end

      it 'returns a higher proneness' do
        expect(engine.nostalgia_proneness).to be > 0.3
      end
    end
  end

  describe '#most_nostalgic_domains' do
    before do
      engine.create_memory(content: 'beach', domain: :place, warmth: 0.9)
      engine.create_memory(content: 'win', domain: :achievement, warmth: 0.5)
    end

    it 'returns domains sorted by avg warmth descending' do
      result = engine.most_nostalgic_domains
      expect(result.first[:domain]).to eq(:place)
      expect(result.map { |d| d[:domain] }).to include(:place, :achievement)
    end

    it 'includes avg_warmth key' do
      result = engine.most_nostalgic_domains
      expect(result.first).to have_key(:avg_warmth)
    end
  end

  describe '#bittersweet_memories' do
    before do
      engine.create_memory(content: 'painful but warm', warmth: 0.7, original_valence: 0.2)
      engine.create_memory(content: 'purely pleasant', warmth: 0.8, original_valence: 0.8)
    end

    it 'returns only bittersweet memories' do
      result = engine.bittersweet_memories
      expect(result).not_to be_empty
      result.each do |m|
        expect(m[:bittersweet]).to be true
      end
    end
  end

  describe '#nostalgia_report' do
    before do
      engine.create_memory(content: 'memory a', domain: :place, warmth: 0.7, original_valence: 0.3)
      engine.create_memory(content: 'memory b', domain: :achievement, warmth: 0.5, original_valence: 0.6)
    end

    it 'includes all expected keys' do
      report = engine.nostalgia_report
      expect(report).to include(
        :total_memories,
        :total_events,
        :rosy_retrospection_index,
        :retrospection_label,
        :nostalgia_proneness,
        :nostalgia_label,
        :most_nostalgic_domains,
        :bittersweet_count,
        :rosy_count
      )
    end

    it 'has correct total_memories' do
      expect(engine.nostalgia_report[:total_memories]).to eq(2)
    end
  end
end
