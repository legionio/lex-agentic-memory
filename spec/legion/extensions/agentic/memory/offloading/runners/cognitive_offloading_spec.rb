# frozen_string_literal: true

require 'legion/extensions/agentic/memory/offloading/client'

RSpec.describe Legion::Extensions::Agentic::Memory::Offloading::Runners::CognitiveOffloading do
  let(:engine) { Legion::Extensions::Agentic::Memory::Offloading::Helpers::OffloadingEngine.new }
  let(:client) { Legion::Extensions::Agentic::Memory::Offloading::Client.new(engine: engine) }

  let(:store) do
    client.register_store(name: 'test_store', store_type: :database)
    engine.stores.values.first
  end

  before { store }

  describe '#register_store' do
    it 'returns success: true on valid registration' do
      result = client.register_store(name: 'another_store', store_type: :file)
      expect(result[:success]).to be true
    end

    it 'returns the store hash' do
      result = client.register_store(name: 'notes', store_type: :notes)
      expect(result[:store]).to include(:id, :name, :store_type, :trust)
    end

    it 'returns success: false when limit reached' do
      stub_const('Legion::Extensions::Agentic::Memory::Offloading::Helpers::Constants::MAX_STORES', 1)
      fresh = Legion::Extensions::Agentic::Memory::Offloading::Client.new
      fresh.register_store(name: 'first', store_type: :file)
      result = fresh.register_store(name: 'overflow', store_type: :file)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:limit_reached)
    end

    it 'accepts an injected engine' do
      injected = Legion::Extensions::Agentic::Memory::Offloading::Helpers::OffloadingEngine.new
      result = client.register_store(name: 'injected', store_type: :agent, engine: injected)
      expect(result[:success]).to be true
    end
  end

  describe '#offload_item' do
    it 'returns success: true on valid offload' do
      result = client.offload_item(content: 'fact', item_type: :fact, importance: 0.7, store_id: store.id)
      expect(result[:success]).to be true
    end

    it 'returns the item hash' do
      result = client.offload_item(content: 'plan', item_type: :plan, importance: 0.8, store_id: store.id)
      expect(result[:item]).to include(:id, :content, :item_type, :importance)
    end

    it 'returns success: false for unknown store_id' do
      result = client.offload_item(content: 'x', item_type: :fact, importance: 0.5, store_id: 'bogus')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:offload_failed)
    end

    it 'returns success: false when item limit reached' do
      stub_const('Legion::Extensions::Agentic::Memory::Offloading::Helpers::Constants::MAX_ITEMS', 1)
      client.offload_item(content: 'first', item_type: :fact, importance: 0.5, store_id: store.id)
      result = client.offload_item(content: 'second', item_type: :fact, importance: 0.5, store_id: store.id)
      expect(result[:success]).to be false
    end
  end

  describe '#retrieve_item' do
    let!(:offloaded) do
      client.offload_item(content: 'my fact', item_type: :fact, importance: 0.6, store_id: store.id)[:item]
    end

    it 'returns success: true for known item' do
      result = client.retrieve_item(item_id: offloaded[:id])
      expect(result[:success]).to be true
    end

    it 'returns the item hash on success' do
      result = client.retrieve_item(item_id: offloaded[:id])
      expect(result[:item]).to include(:id, :retrieved_count)
    end

    it 'increments retrieved_count' do
      client.retrieve_item(item_id: offloaded[:id])
      result = client.retrieve_item(item_id: offloaded[:id])
      expect(result[:item][:retrieved_count]).to eq(2)
    end

    it 'returns success: false for unknown item_id' do
      result = client.retrieve_item(item_id: 'no-such-item')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#report_retrieval_failure' do
    let!(:offloaded) do
      client.offload_item(content: 'plan', item_type: :plan, importance: 0.5, store_id: store.id)[:item]
    end

    it 'returns success: true for known item' do
      result = client.report_retrieval_failure(item_id: offloaded[:id])
      expect(result[:success]).to be true
    end

    it 'returns current store_trust' do
      result = client.report_retrieval_failure(item_id: offloaded[:id])
      expect(result[:store_trust]).to be_a(Float)
    end

    it 'decays trust on the store' do
      trust_before = store.trust
      client.report_retrieval_failure(item_id: offloaded[:id])
      expect(store.trust).to be < trust_before
    end

    it 'returns success: false for unknown item_id' do
      result = client.report_retrieval_failure(item_id: 'ghost')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#items_in_store' do
    it 'returns items belonging to the store' do
      client.offload_item(content: 'a', item_type: :fact, importance: 0.5, store_id: store.id)
      client.offload_item(content: 'b', item_type: :reminder, importance: 0.3, store_id: store.id)
      result = client.items_in_store(store_id: store.id)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(2)
    end

    it 'returns empty list for store with no items' do
      result = client.items_in_store(store_id: store.id)
      expect(result[:items]).to eq([])
    end
  end

  describe '#items_by_type' do
    before do
      client.offload_item(content: 'a', item_type: :calculation, importance: 0.4, store_id: store.id)
      client.offload_item(content: 'b', item_type: :calculation, importance: 0.6, store_id: store.id)
      client.offload_item(content: 'c', item_type: :delegation, importance: 0.8, store_id: store.id)
    end

    it 'returns items of matching type' do
      result = client.items_by_type(item_type: :calculation)
      expect(result[:count]).to eq(2)
    end

    it 'returns 0 for unused type' do
      result = client.items_by_type(item_type: :reference)
      expect(result[:count]).to eq(0)
    end
  end

  describe '#most_important_offloaded' do
    before do
      client.offload_item(content: 'low',  item_type: :fact, importance: 0.2, store_id: store.id)
      client.offload_item(content: 'high', item_type: :fact, importance: 0.95, store_id: store.id)
      client.offload_item(content: 'mid',  item_type: :fact, importance: 0.5, store_id: store.id)
    end

    it 'returns items in importance-descending order' do
      result = client.most_important_offloaded(limit: 3)
      importances = result[:items].map { |i| i[:importance] }
      expect(importances).to eq(importances.sort.reverse)
    end

    it 'respects the limit parameter' do
      result = client.most_important_offloaded(limit: 2)
      expect(result[:count]).to eq(2)
    end
  end

  describe '#offloading_status' do
    it 'returns success: true' do
      result = client.offloading_status
      expect(result[:success]).to be true
    end

    it 'includes the offloading report' do
      result = client.offloading_status
      expect(result[:report]).to include(:total_items, :total_stores, :offloading_ratio,
                                         :overall_store_trust, :stores_summary)
    end

    it 'reflects current item count' do
      client.offload_item(content: 'x', item_type: :context, importance: 0.5, store_id: store.id)
      result = client.offloading_status
      expect(result[:report][:total_items]).to eq(1)
    end
  end
end
