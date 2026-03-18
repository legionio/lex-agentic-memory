# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Offloading::Helpers::ExternalStore do
  let(:store) { described_class.new(name: 'notes_db', store_type: :database) }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(store.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores name' do
      expect(store.name).to eq('notes_db')
    end

    it 'stores store_type' do
      expect(store.store_type).to eq(:database)
    end

    it 'defaults trust to DEFAULT_STORE_TRUST (0.7)' do
      expect(store.trust).to eq(0.7)
    end

    it 'initializes items_stored to 0' do
      expect(store.items_stored).to eq(0)
    end

    it 'initializes successful_retrievals to 0' do
      expect(store.successful_retrievals).to eq(0)
    end

    it 'initializes failed_retrievals to 0' do
      expect(store.failed_retrievals).to eq(0)
    end

    it 'records created_at as a Time' do
      expect(store.created_at).to be_a(Time)
    end
  end

  describe '#increment_items!' do
    it 'increments items_stored' do
      store.increment_items!
      expect(store.items_stored).to eq(1)
    end

    it 'returns self for chaining' do
      expect(store.increment_items!).to eq(store)
    end
  end

  describe '#record_success!' do
    it 'increments successful_retrievals' do
      store.record_success!
      expect(store.successful_retrievals).to eq(1)
    end

    it 'boosts trust by TRUST_BOOST' do
      trust_before = store.trust
      store.record_success!
      expect(store.trust).to be > trust_before
    end

    it 'does not exceed trust of 1.0' do
      10.times { store.record_success! }
      expect(store.trust).to be <= 1.0
    end

    it 'returns self for chaining' do
      expect(store.record_success!).to eq(store)
    end
  end

  describe '#record_failure!' do
    it 'increments failed_retrievals' do
      store.record_failure!
      expect(store.failed_retrievals).to eq(1)
    end

    it 'decays trust by TRUST_DECAY' do
      trust_before = store.trust
      store.record_failure!
      expect(store.trust).to be < trust_before
    end

    it 'does not drop trust below 0.0' do
      20.times { store.record_failure! }
      expect(store.trust).to be >= 0.0
    end

    it 'returns self for chaining' do
      expect(store.record_failure!).to eq(store)
    end
  end

  describe '#retrieval_rate' do
    it 'returns 0.0 with no retrievals' do
      expect(store.retrieval_rate).to eq(0.0)
    end

    it 'returns 1.0 when all retrievals succeed' do
      3.times { store.record_success! }
      expect(store.retrieval_rate).to eq(1.0)
    end

    it 'returns 0.5 for equal success/failure' do
      store.record_success!
      store.record_failure!
      expect(store.retrieval_rate).to eq(0.5)
    end

    it 'rounds to 10 decimal places' do
      2.times { store.record_success! }
      store.record_failure!
      expect(store.retrieval_rate).to eq((2.0 / 3).round(10))
    end
  end

  describe '#reliable?' do
    it 'returns true when trust >= 0.7' do
      expect(store.reliable?).to be true
    end

    it 'returns false when trust drops below 0.7' do
      4.times { store.record_failure! }
      expect(store.reliable?).to be false
    end
  end

  describe '#trust_label' do
    it 'returns :trusted for default trust of 0.7' do
      expect(store.trust_label).to eq(:trusted)
    end

    it 'returns :highly_trusted after many successes' do
      5.times { store.record_success! }
      expect(store.trust_label).to eq(:highly_trusted)
    end

    it 'returns :unreliable after many failures' do
      30.times { store.record_failure! }
      expect(store.trust_label).to eq(:unreliable)
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = store.to_h
      expect(h).to include(:id, :name, :store_type, :trust, :trust_label, :items_stored,
                           :successful_retrievals, :failed_retrievals, :retrieval_rate,
                           :reliable, :created_at)
    end

    it 'reflects current trust value' do
      store.record_failure!
      expect(store.to_h[:trust]).to eq(store.trust)
    end
  end
end
