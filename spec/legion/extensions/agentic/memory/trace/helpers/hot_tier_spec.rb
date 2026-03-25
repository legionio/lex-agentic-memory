# frozen_string_literal: true

require 'spec_helper'

# Legion::Cache::RedisHash lives in legion-cache. The installed gem version may not have it
# yet, so we define a minimal stub for testing HotTier in isolation.
unless defined?(Legion::Cache::RedisHash)
  module Legion
    module Cache
      module RedisHash
        module_function

        def redis_available? = false
        def hset(_key, _hash) = false
        def hgetall(_key) = nil
        def hdel(_key, *_fields) = 0
        def zadd(_key, _score, _member) = false
        def zrangebyscore(_key, _min, _max, **) = []
        def zrem(_key, _member) = false
        def expire(_key, _seconds) = false
      end
    end
  end
end

RSpec.describe Legion::Extensions::Agentic::Memory::Trace::Helpers::HotTier do
  subject(:mod) { described_class }

  let(:tenant_id) { 'tenant-abc' }
  let(:trace_id)  { 'trace-uuid-001' }

  let(:trace) do
    {
      trace_id:        trace_id,
      trace_type:      :semantic,
      content_payload: 'ruby is great',
      strength:        0.85,
      peak_strength:   0.95,
      confidence:      0.9,
      partition_id:    tenant_id,
      last_reinforced: Time.now
    }
  end

  # --- available? ---

  describe '.available?' do
    context 'when Legion::Cache::RedisHash is not defined' do
      it 'returns a falsy value gracefully' do
        hide_const('Legion::Cache::RedisHash')
        expect(mod.available?).to be_falsy
      end
    end

    context 'when Legion::Cache::RedisHash is defined but not connected' do
      before do
        stub_const('Legion::Cache::RedisHash', Module.new)
        allow(Legion::Cache::RedisHash).to receive(:redis_available?).and_return(false)
      end

      it 'returns false' do
        expect(mod.available?).to be false
      end
    end

    context 'when Legion::Cache::RedisHash is defined and connected' do
      before do
        stub_const('Legion::Cache::RedisHash', Module.new)
        allow(Legion::Cache::RedisHash).to receive(:redis_available?).and_return(true)
      end

      it 'returns true' do
        expect(mod.available?).to be true
      end
    end

    context 'when an exception is raised' do
      before { allow(mod).to receive(:available?).and_call_original }

      it 'returns false without raising' do
        stub_const('Legion::Cache::RedisHash', Module.new)
        allow(Legion::Cache::RedisHash).to receive(:redis_available?).and_raise(RuntimeError, 'boom')
        expect(mod.available?).to be false
      end
    end
  end

  # --- trace_key ---

  describe '.trace_key' do
    it 'builds a namespaced key from tenant and trace id' do
      expect(mod.trace_key('tenant-1', 'trace-2')).to eq('legion:trace:tenant-1:trace-2')
    end

    it 'handles nil tenant gracefully' do
      expect(mod.trace_key(nil, 'trace-2')).to eq('legion:trace::trace-2')
    end
  end

  # --- serialize_trace / deserialize_trace round-trip ---

  describe '.serialize_trace' do
    subject(:serialized) { mod.serialize_trace(trace) }

    it 'returns a Hash with string keys only' do
      expect(serialized.keys).to all(be_a(String))
    end

    it 'includes all expected fields' do
      expect(serialized.keys).to include(
        'trace_id', 'trace_type', 'content_payload',
        'strength', 'peak_strength', 'confidence',
        'storage_tier', 'partition_id', 'last_reinforced'
      )
    end

    it 'sets storage_tier to "hot"' do
      expect(serialized['storage_tier']).to eq('hot')
    end

    it 'converts trace_id to string' do
      expect(serialized['trace_id']).to eq(trace_id)
    end

    it 'converts trace_type to string' do
      expect(serialized['trace_type']).to eq('semantic')
    end

    it 'converts numeric fields to strings' do
      expect(serialized['strength']).to eq('0.85')
      expect(serialized['peak_strength']).to eq('0.95')
      expect(serialized['confidence']).to eq('0.9')
    end

    it 'uses Time.now when last_reinforced is nil' do
      t = mod.serialize_trace(trace.merge(last_reinforced: nil))
      expect(t['last_reinforced']).not_to be_empty
    end
  end

  describe '.deserialize_trace' do
    let(:data) do
      {
        'trace_id'        => trace_id,
        'trace_type'      => 'semantic',
        'content_payload' => 'ruby is great',
        'strength'        => '0.85',
        'peak_strength'   => '0.95',
        'confidence'      => '0.9',
        'storage_tier'    => 'hot',
        'partition_id'    => tenant_id,
        'last_reinforced' => Time.now.to_s
      }
    end

    subject(:deserialized) { mod.deserialize_trace(data) }

    it 'returns a hash with symbol keys' do
      expect(deserialized).to be_a(Hash)
      expect(deserialized.keys).to all(be_a(Symbol))
    end

    it 'sets trace_id correctly' do
      expect(deserialized[:trace_id]).to eq(trace_id)
    end

    it 'converts trace_type back to a symbol' do
      expect(deserialized[:trace_type]).to eq(:semantic)
    end

    it 'converts numeric strings back to floats' do
      expect(deserialized[:strength]).to be_within(0.001).of(0.85)
      expect(deserialized[:peak_strength]).to be_within(0.001).of(0.95)
      expect(deserialized[:confidence]).to be_within(0.001).of(0.9)
    end

    it 'forces storage_tier to :hot' do
      expect(deserialized[:storage_tier]).to eq(:hot)
    end

    it 'preserves partition_id' do
      expect(deserialized[:partition_id]).to eq(tenant_id)
    end
  end

  describe 'serialize -> deserialize round-trip' do
    it 'recovers numeric values from serialized form' do
      serialized   = mod.serialize_trace(trace)
      deserialized = mod.deserialize_trace(serialized)

      expect(deserialized[:trace_id]).to eq(trace[:trace_id])
      expect(deserialized[:trace_type]).to eq(trace[:trace_type])
      expect(deserialized[:strength]).to be_within(0.001).of(trace[:strength])
      expect(deserialized[:confidence]).to be_within(0.001).of(trace[:confidence])
      expect(deserialized[:storage_tier]).to eq(:hot)
    end
  end

  # --- cache_trace ---

  describe '.cache_trace' do
    context 'when unavailable' do
      before { allow(mod).to receive(:available?).and_return(false) }

      it 'returns nil without calling RedisHash' do
        expect(Legion::Cache::RedisHash).not_to receive(:hset)
        expect(mod.cache_trace(trace, tenant_id: tenant_id)).to be_nil
      end
    end

    context 'when available' do
      before do
        allow(mod).to receive(:available?).and_return(true)
        allow(Legion::Cache::RedisHash).to receive(:hset).and_return(true)
        allow(Legion::Cache::RedisHash).to receive(:expire).and_return(true)
        allow(Legion::Cache::RedisHash).to receive(:zadd).and_return(true)
      end

      it 'calls hset with the correct key and serialized data' do
        key = mod.trace_key(tenant_id, trace_id)
        expect(Legion::Cache::RedisHash).to receive(:hset).with(key, hash_including('trace_id' => trace_id))
        mod.cache_trace(trace, tenant_id: tenant_id)
      end

      it 'calls expire with HOT_TTL' do
        key = mod.trace_key(tenant_id, trace_id)
        expect(Legion::Cache::RedisHash).to receive(:expire).with(key, described_class::HOT_TTL)
        mod.cache_trace(trace, tenant_id: tenant_id)
      end

      it 'adds to the sorted-set index' do
        index_key = "legion:tier:hot:#{tenant_id}"
        expect(Legion::Cache::RedisHash).to receive(:zadd).with(index_key, anything, trace_id)
        mod.cache_trace(trace, tenant_id: tenant_id)
      end

      it 'falls back to partition_id when tenant_id is not provided' do
        key = mod.trace_key(trace[:partition_id], trace_id)
        expect(Legion::Cache::RedisHash).to receive(:hset).with(key, anything)
        mod.cache_trace(trace)
      end
    end
  end

  # --- fetch_trace ---

  describe '.fetch_trace' do
    context 'when unavailable' do
      before { allow(mod).to receive(:available?).and_return(false) }

      it 'returns nil' do
        expect(mod.fetch_trace(trace_id, tenant_id: tenant_id)).to be_nil
      end
    end

    context 'when available but key is missing' do
      before do
        allow(mod).to receive(:available?).and_return(true)
        allow(Legion::Cache::RedisHash).to receive(:hgetall).and_return({})
      end

      it 'returns nil' do
        expect(mod.fetch_trace(trace_id, tenant_id: tenant_id)).to be_nil
      end
    end

    context 'when available and key exists' do
      let(:cached_data) do
        {
          'trace_id'        => trace_id,
          'trace_type'      => 'semantic',
          'content_payload' => 'ruby is great',
          'strength'        => '0.85',
          'peak_strength'   => '0.95',
          'confidence'      => '0.9',
          'storage_tier'    => 'hot',
          'partition_id'    => tenant_id,
          'last_reinforced' => Time.now.to_s
        }
      end

      before do
        allow(mod).to receive(:available?).and_return(true)
        allow(Legion::Cache::RedisHash).to receive(:hgetall).and_return(cached_data)
      end

      it 'returns a deserialized trace hash' do
        result = mod.fetch_trace(trace_id, tenant_id: tenant_id)
        expect(result).not_to be_nil
        expect(result[:trace_id]).to eq(trace_id)
        expect(result[:trace_type]).to eq(:semantic)
        expect(result[:storage_tier]).to eq(:hot)
      end
    end
  end

  # --- evict_trace ---

  describe '.evict_trace' do
    context 'when unavailable' do
      before { allow(mod).to receive(:available?).and_return(false) }

      it 'returns nil without calling Cache.delete' do
        expect(Legion::Cache).not_to receive(:delete)
        expect(mod.evict_trace(trace_id, tenant_id: tenant_id)).to be_nil
      end
    end

    context 'when available' do
      before do
        allow(mod).to receive(:available?).and_return(true)
        allow(Legion::Cache).to receive(:delete).and_return(true)
        allow(Legion::Cache::RedisHash).to receive(:zrem).and_return(true)
      end

      it 'deletes the trace key from Cache' do
        key = mod.trace_key(tenant_id, trace_id)
        expect(Legion::Cache).to receive(:delete).with(key)
        mod.evict_trace(trace_id, tenant_id: tenant_id)
      end

      it 'removes the entry from the sorted-set index' do
        index_key = "legion:tier:hot:#{tenant_id}"
        expect(Legion::Cache::RedisHash).to receive(:zrem).with(index_key, trace_id)
        mod.evict_trace(trace_id, tenant_id: tenant_id)
      end
    end
  end

  # --- HOT_TTL constant ---

  describe 'HOT_TTL' do
    it 'is 86400 (24 hours in seconds)' do
      expect(described_class::HOT_TTL).to eq(86_400)
    end
  end
end
