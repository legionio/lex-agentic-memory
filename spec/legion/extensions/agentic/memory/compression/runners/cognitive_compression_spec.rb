# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Compression::Runners::CognitiveCompression do
  let(:client) { Legion::Extensions::Agentic::Memory::Compression::Client.new }

  describe '#store_chunk' do
    it 'returns success with chunk hash' do
      result = client.store_chunk(label: 'test')
      expect(result[:success]).to be true
      expect(result[:chunk]).to include(:id, :label, :compression_ratio)
    end
  end

  describe '#compress_chunk' do
    it 'compresses a stored chunk' do
      c = client.store_chunk(label: 'data')
      result = client.compress_chunk(chunk_id: c[:chunk][:id])
      expect(result[:success]).to be true
      expect(result[:chunk][:compression_ratio]).to be > 0.0
    end

    it 'returns failure for unknown id' do
      result = client.compress_chunk(chunk_id: 'fake')
      expect(result[:success]).to be false
    end
  end

  describe '#decompress_chunk' do
    it 'decompresses a chunk' do
      c = client.store_chunk(label: 'data')
      client.compress_chunk(chunk_id: c[:chunk][:id])
      result = client.decompress_chunk(chunk_id: c[:chunk][:id])
      expect(result[:success]).to be true
    end
  end

  describe '#abstract_chunks' do
    it 'creates an abstraction' do
      c1 = client.store_chunk(label: 'a')
      c2 = client.store_chunk(label: 'b')
      result = client.abstract_chunks(chunk_ids:         [c1[:chunk][:id], c2[:chunk][:id]],
                                      abstraction_label: 'ab')
      expect(result[:success]).to be true
      expect(result[:abstraction][:chunk_type]).to eq(:abstract)
    end
  end

  describe '#compress_all' do
    it 'returns compressed count' do
      client.store_chunk(label: 'a')
      client.store_chunk(label: 'b')
      result = client.compress_all
      expect(result[:success]).to be true
      expect(result[:compressed_count]).to eq(2)
    end
  end

  describe '#average_fidelity' do
    it 'returns fidelity score' do
      result = client.average_fidelity
      expect(result[:success]).to be true
      expect(result[:fidelity]).to be_a(Numeric)
    end
  end

  describe '#overall_compression_ratio' do
    it 'returns ratio' do
      result = client.overall_compression_ratio
      expect(result[:success]).to be true
    end
  end

  describe '#compression_report' do
    it 'returns a full report' do
      result = client.compression_report
      expect(result[:success]).to be true
      expect(result[:report]).to include(:total_chunks, :average_fidelity)
    end
  end
end
