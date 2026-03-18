# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Offloading::Helpers::OffloadedItem do
  let(:store_id) { SecureRandom.uuid }
  let(:item) do
    described_class.new(
      content:    'The capital of France is Paris',
      item_type:  :fact,
      importance: 0.8,
      store_id:   store_id
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(item.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores content' do
      expect(item.content).to eq('The capital of France is Paris')
    end

    it 'stores item_type' do
      expect(item.item_type).to eq(:fact)
    end

    it 'stores importance' do
      expect(item.importance).to eq(0.8)
    end

    it 'stores store_id' do
      expect(item.store_id).to eq(store_id)
    end

    it 'clamps importance above 1.0 to 1.0' do
      overimportant = described_class.new(content: 'x', item_type: :fact, importance: 1.5, store_id: store_id)
      expect(overimportant.importance).to eq(1.0)
    end

    it 'clamps importance below 0.0 to 0.0' do
      negative = described_class.new(content: 'x', item_type: :fact, importance: -0.5, store_id: store_id)
      expect(negative.importance).to eq(0.0)
    end

    it 'initializes retrieved_count to 0' do
      expect(item.retrieved_count).to eq(0)
    end

    it 'initializes last_retrieved_at to nil' do
      expect(item.last_retrieved_at).to be_nil
    end

    it 'records offloaded_at as a Time' do
      expect(item.offloaded_at).to be_a(Time)
    end
  end

  describe '#retrieve!' do
    it 'increments retrieved_count' do
      item.retrieve!
      expect(item.retrieved_count).to eq(1)
    end

    it 'updates last_retrieved_at' do
      item.retrieve!
      expect(item.last_retrieved_at).to be_a(Time)
    end

    it 'returns self for chaining' do
      expect(item.retrieve!).to eq(item)
    end

    it 'accumulates multiple retrievals' do
      3.times { item.retrieve! }
      expect(item.retrieved_count).to eq(3)
    end
  end

  describe '#stale?' do
    it 'returns false for newly offloaded item with no retrievals' do
      expect(item.stale?(threshold_seconds: 3600)).to be false
    end

    it 'returns true when last retrieved time exceeds threshold' do
      item.retrieve!
      item.instance_variable_set(:@last_retrieved_at, Time.now.utc - 7200)
      expect(item.stale?(threshold_seconds: 3600)).to be true
    end

    it 'returns false when within threshold' do
      item.retrieve!
      expect(item.stale?(threshold_seconds: 3600)).to be false
    end
  end

  describe '#importance_label' do
    it 'returns :critical for high importance' do
      expect(item.importance_label).to eq(:critical)
    end

    it 'returns :trivial for very low importance' do
      trivial = described_class.new(content: 'x', item_type: :fact, importance: 0.1, store_id: store_id)
      expect(trivial.importance_label).to eq(:trivial)
    end

    it 'returns :moderate for mid-range importance' do
      moderate = described_class.new(content: 'x', item_type: :fact, importance: 0.5, store_id: store_id)
      expect(moderate.importance_label).to eq(:moderate)
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = item.to_h
      expect(h).to include(:id, :content, :item_type, :importance, :importance_label,
                           :store_id, :offloaded_at, :retrieved_count, :last_retrieved_at)
    end

    it 'rounds importance to 10 decimal places' do
      expect(item.to_h[:importance]).to eq(item.importance.round(10))
    end
  end
end
