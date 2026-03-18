# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Compression::Helpers::CompressionEngine do
  subject(:engine) { described_class.new }

  let(:chunk) { engine.store_chunk(label: 'test') }

  describe '#store_chunk' do
    it 'returns an InformationChunk' do
      expect(chunk).to be_a(Legion::Extensions::Agentic::Memory::Compression::Helpers::InformationChunk)
    end

    it 'increases chunk count' do
      chunk
      expect(engine.to_h[:total_chunks]).to eq(1)
    end

    it 'accepts type and size' do
      c = engine.store_chunk(label: 'big', chunk_type: :episodic, original_size: 5.0)
      expect(c.chunk_type).to eq(:episodic)
      expect(c.original_size).to eq(5.0)
    end
  end

  describe '#compress_chunk' do
    it 'reduces the chunk compressed_size' do
      original = chunk.compressed_size
      engine.compress_chunk(chunk_id: chunk.id)
      expect(chunk.compressed_size).to be < original
    end

    it 'returns nil for unknown id' do
      expect(engine.compress_chunk(chunk_id: 'fake')).to be_nil
    end
  end

  describe '#decompress_chunk' do
    it 'increases compressed_size after compression' do
      engine.compress_chunk(chunk_id: chunk.id)
      small = chunk.compressed_size
      engine.decompress_chunk(chunk_id: chunk.id)
      expect(chunk.compressed_size).to be > small
    end
  end

  describe '#abstract_chunks' do
    it 'creates an abstraction from multiple chunks' do
      c1 = engine.store_chunk(label: 'a')
      c2 = engine.store_chunk(label: 'b')
      abstraction = engine.abstract_chunks(chunk_ids:         [c1.id, c2.id],
                                           abstraction_label: 'combined')
      expect(abstraction).to be_a(Legion::Extensions::Agentic::Memory::Compression::Helpers::InformationChunk)
      expect(abstraction.chunk_type).to eq(:abstract)
    end

    it 'returns nil for empty chunk_ids' do
      expect(engine.abstract_chunks(chunk_ids: ['fake'], abstraction_label: 'x')).to be_nil
    end
  end

  describe '#compress_all' do
    it 'compresses every stored chunk' do
      3.times { |i| engine.store_chunk(label: "c#{i}") }
      count = engine.compress_all
      expect(count).to eq(3)
    end
  end

  describe '#chunks_by_type' do
    it 'filters by type' do
      engine.store_chunk(label: 'epi', chunk_type: :episodic)
      engine.store_chunk(label: 'sem', chunk_type: :semantic)
      result = engine.chunks_by_type(chunk_type: :episodic)
      expect(result.size).to eq(1)
    end
  end

  describe '#average_compression_ratio' do
    it 'returns 0.0 with no chunks' do
      expect(engine.average_compression_ratio).to eq(0.0)
    end

    it 'increases after compression' do
      engine.store_chunk(label: 'a')
      engine.compress_all
      expect(engine.average_compression_ratio).to be > 0.0
    end
  end

  describe '#average_fidelity' do
    it 'returns 1.0 with no chunks' do
      expect(engine.average_fidelity).to eq(1.0)
    end

    it 'decreases after compression' do
      engine.store_chunk(label: 'a')
      engine.compress_all
      expect(engine.average_fidelity).to be < 1.0
    end
  end

  describe '#overall_compression_ratio' do
    it 'returns 0.0 with no chunks' do
      expect(engine.overall_compression_ratio).to eq(0.0)
    end
  end

  describe '#compression_report' do
    it 'includes all report fields' do
      chunk
      report = engine.compression_report
      expect(report).to include(
        :total_chunks, :total_abstractions, :average_compression_ratio,
        :overall_compression_ratio, :average_fidelity,
        :total_original_size, :total_compressed_size, :highly_compressed_count
      )
    end
  end

  describe '#to_h' do
    it 'includes summary fields' do
      hash = engine.to_h
      expect(hash).to include(
        :total_chunks, :total_abstractions,
        :average_compression_ratio, :average_fidelity
      )
    end
  end

  describe 'pruning' do
    it 'prunes oldest chunk when limit reached' do
      stub_const('Legion::Extensions::Agentic::Memory::Compression::Helpers::Constants::MAX_CHUNKS', 3)
      eng = described_class.new
      4.times { |i| eng.store_chunk(label: "c#{i}") }
      expect(eng.to_h[:total_chunks]).to eq(3)
    end
  end
end
