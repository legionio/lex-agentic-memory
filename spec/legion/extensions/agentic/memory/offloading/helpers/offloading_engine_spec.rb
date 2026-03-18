# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Offloading::Helpers::OffloadingEngine do
  let(:engine) { described_class.new }
  let(:store) { engine.register_store(name: 'my_store', store_type: :database) }

  describe '#register_store' do
    it 'creates and returns a store' do
      expect(store).to be_a(Legion::Extensions::Agentic::Memory::Offloading::Helpers::ExternalStore)
    end

    it 'adds the store to @stores' do
      store
      expect(engine.stores.size).to eq(1)
    end

    it 'returns nil when at MAX_STORES limit' do
      stub_const('Legion::Extensions::Agentic::Memory::Offloading::Helpers::Constants::MAX_STORES', 1)
      engine.register_store(name: 'first', store_type: :file)
      second = engine.register_store(name: 'second', store_type: :file)
      expect(second).to be_nil
    end
  end

  describe '#offload' do
    it 'creates and returns an offloaded item' do
      item = engine.offload(content: 'remember this', item_type: :fact, importance: 0.6, store_id: store.id)
      expect(item).to be_a(Legion::Extensions::Agentic::Memory::Offloading::Helpers::OffloadedItem)
    end

    it 'adds item to @items' do
      engine.offload(content: 'remember this', item_type: :fact, importance: 0.6, store_id: store.id)
      expect(engine.items.size).to eq(1)
    end

    it 'increments items_stored on the store' do
      engine.offload(content: 'x', item_type: :fact, importance: 0.5, store_id: store.id)
      expect(store.items_stored).to eq(1)
    end

    it 'returns nil for unknown store_id' do
      item = engine.offload(content: 'x', item_type: :fact, importance: 0.5, store_id: 'bad-id')
      expect(item).to be_nil
    end

    it 'returns nil when at MAX_ITEMS limit' do
      stub_const('Legion::Extensions::Agentic::Memory::Offloading::Helpers::Constants::MAX_ITEMS', 1)
      engine.offload(content: 'first', item_type: :fact, importance: 0.5, store_id: store.id)
      second = engine.offload(content: 'second', item_type: :fact, importance: 0.5, store_id: store.id)
      expect(second).to be_nil
    end
  end

  describe '#retrieve' do
    let!(:item) { engine.offload(content: 'test', item_type: :reminder, importance: 0.4, store_id: store.id) }

    it 'returns the item' do
      retrieved = engine.retrieve(item_id: item.id)
      expect(retrieved).to eq(item)
    end

    it 'increments item retrieved_count' do
      engine.retrieve(item_id: item.id)
      expect(item.retrieved_count).to eq(1)
    end

    it 'records success on the store' do
      engine.retrieve(item_id: item.id)
      expect(store.successful_retrievals).to eq(1)
    end

    it 'returns nil for unknown item_id' do
      expect(engine.retrieve(item_id: 'no-such-item')).to be_nil
    end
  end

  describe '#retrieve_failed' do
    let!(:item) { engine.offload(content: 'test', item_type: :fact, importance: 0.5, store_id: store.id) }

    it 'returns the item' do
      expect(engine.retrieve_failed(item_id: item.id)).to eq(item)
    end

    it 'records failure on the store' do
      engine.retrieve_failed(item_id: item.id)
      expect(store.failed_retrievals).to eq(1)
    end

    it 'decays store trust' do
      trust_before = store.trust
      engine.retrieve_failed(item_id: item.id)
      expect(store.trust).to be < trust_before
    end

    it 'returns nil for unknown item_id' do
      expect(engine.retrieve_failed(item_id: 'ghost')).to be_nil
    end
  end

  describe '#items_in_store' do
    it 'returns items belonging to the given store' do
      engine.offload(content: 'a', item_type: :fact, importance: 0.5, store_id: store.id)
      engine.offload(content: 'b', item_type: :fact, importance: 0.5, store_id: store.id)
      other_store = engine.register_store(name: 'other', store_type: :file)
      engine.offload(content: 'c', item_type: :fact, importance: 0.5, store_id: other_store.id)

      items = engine.items_in_store(store_id: store.id)
      expect(items.size).to eq(2)
    end

    it 'returns empty array for store with no items' do
      expect(engine.items_in_store(store_id: store.id)).to eq([])
    end
  end

  describe '#items_by_type' do
    before do
      engine.offload(content: 'a', item_type: :fact, importance: 0.5, store_id: store.id)
      engine.offload(content: 'b', item_type: :fact, importance: 0.6, store_id: store.id)
      engine.offload(content: 'c', item_type: :plan, importance: 0.7, store_id: store.id)
    end

    it 'returns items of the given type' do
      expect(engine.items_by_type(item_type: :fact).size).to eq(2)
    end

    it 'returns empty array for unused type' do
      expect(engine.items_by_type(item_type: :calculation)).to eq([])
    end
  end

  describe '#most_important_offloaded' do
    before do
      engine.offload(content: 'low',  item_type: :fact, importance: 0.2, store_id: store.id)
      engine.offload(content: 'high', item_type: :fact, importance: 0.9, store_id: store.id)
      engine.offload(content: 'mid',  item_type: :fact, importance: 0.5, store_id: store.id)
    end

    it 'returns items sorted by importance descending' do
      items = engine.most_important_offloaded(limit: 3)
      importances = items.map(&:importance)
      expect(importances).to eq(importances.sort.reverse)
    end

    it 'respects limit' do
      items = engine.most_important_offloaded(limit: 2)
      expect(items.size).to eq(2)
    end

    it 'returns the highest importance item first' do
      items = engine.most_important_offloaded(limit: 1)
      expect(items.first.importance).to eq(0.9)
    end
  end

  describe '#offloading_ratio' do
    it 'returns 0.0 with no items' do
      expect(engine.offloading_ratio).to eq(0.0)
    end

    it 'increases as items are added' do
      engine.offload(content: 'x', item_type: :fact, importance: 0.5, store_id: store.id)
      expect(engine.offloading_ratio).to be > 0.0
    end
  end

  describe '#overall_store_trust' do
    it 'returns 0.0 with no stores' do
      expect(described_class.new.overall_store_trust).to eq(0.0)
    end

    it 'returns average trust across stores' do
      s1 = engine.register_store(name: 's1', store_type: :file)
      s2 = engine.register_store(name: 's2', store_type: :notes)
      s1.record_failure!
      expected = ((s1.trust + s2.trust + store.trust) / 3.0).round(10)
      expect(engine.overall_store_trust).to eq(expected)
    end
  end

  describe '#most_trusted_store' do
    it 'returns nil with no stores' do
      expect(described_class.new.most_trusted_store).to be_nil
    end

    it 'returns the store with highest trust' do
      s2 = engine.register_store(name: 's2', store_type: :file)
      s2.record_success!
      expect(engine.most_trusted_store.trust).to be >= store.trust
    end
  end

  describe '#least_trusted_store' do
    it 'returns nil with no stores' do
      expect(described_class.new.least_trusted_store).to be_nil
    end

    it 'returns the store with lowest trust' do
      s2 = engine.register_store(name: 's2', store_type: :file)
      3.times { s2.record_failure! }
      expect(engine.least_trusted_store.trust).to be <= store.trust
    end
  end

  describe '#offloading_report' do
    before do
      engine.offload(content: 'fact one', item_type: :fact, importance: 0.8, store_id: store.id)
      engine.offload(content: 'plan one', item_type: :plan, importance: 0.6, store_id: store.id)
    end

    it 'includes total_items count' do
      expect(engine.offloading_report[:total_items]).to eq(2)
    end

    it 'includes total_stores count' do
      expect(engine.offloading_report[:total_stores]).to eq(1)
    end

    it 'includes offloading_ratio' do
      expect(engine.offloading_report[:offloading_ratio]).to be > 0.0
    end

    it 'includes offloading_label' do
      expect(engine.offloading_report[:offloading_label]).to be_a(Symbol)
    end

    it 'includes overall_store_trust' do
      expect(engine.offloading_report[:overall_store_trust]).to be_a(Float)
    end

    it 'includes stores_summary array' do
      expect(engine.offloading_report[:stores_summary]).to be_an(Array)
    end

    it 'includes items_by_type breakdown' do
      breakdown = engine.offloading_report[:items_by_type]
      expect(breakdown[:fact]).to eq(1)
      expect(breakdown[:plan]).to eq(1)
    end
  end

  describe '#to_h' do
    it 'returns items and stores as hashes' do
      engine.offload(content: 'x', item_type: :fact, importance: 0.5, store_id: store.id)
      h = engine.to_h
      expect(h).to have_key(:items)
      expect(h).to have_key(:stores)
    end
  end
end
