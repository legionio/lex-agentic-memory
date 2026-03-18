# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Compression::Helpers::InformationChunk do
  subject(:chunk) { described_class.new(label: 'test_data') }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(chunk.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets label' do
      expect(chunk.label).to eq('test_data')
    end

    it 'defaults to semantic type' do
      expect(chunk.chunk_type).to eq(:semantic)
    end

    it 'starts with fidelity 1.0' do
      expect(chunk.fidelity).to eq(1.0)
    end

    it 'starts with 0 compressions' do
      expect(chunk.compression_count).to eq(0)
    end

    it 'original and compressed sizes start equal' do
      expect(chunk.compressed_size).to eq(chunk.original_size)
    end
  end

  describe '#compression_ratio' do
    it 'starts at 0.0 (no compression)' do
      expect(chunk.compression_ratio).to eq(0.0)
    end

    it 'increases after compression' do
      chunk.compress!
      expect(chunk.compression_ratio).to be > 0.0
    end
  end

  describe '#compress!' do
    it 'reduces compressed_size' do
      original = chunk.compressed_size
      chunk.compress!
      expect(chunk.compressed_size).to be < original
    end

    it 'reduces fidelity' do
      chunk.compress!
      expect(chunk.fidelity).to be < 1.0
    end

    it 'increments compression_count' do
      chunk.compress!
      expect(chunk.compression_count).to eq(1)
    end

    it 'fidelity floors at MIN_FIDELITY' do
      50.times { chunk.compress! }
      min = Legion::Extensions::Agentic::Memory::Compression::Helpers::Constants::MIN_FIDELITY
      expect(chunk.fidelity).to be >= min
    end

    it 'returns self' do
      expect(chunk.compress!).to eq(chunk)
    end
  end

  describe '#decompress!' do
    it 'increases compressed_size' do
      chunk.compress!
      small = chunk.compressed_size
      chunk.decompress!
      expect(chunk.compressed_size).to be > small
    end

    it 'does not exceed original_size' do
      chunk.decompress!
      expect(chunk.compressed_size).to be <= chunk.original_size
    end
  end

  describe '#highly_compressed?' do
    it 'is false at start' do
      expect(chunk.highly_compressed?).to be false
    end

    it 'is true after many compressions' do
      20.times { chunk.compress! }
      expect(chunk.highly_compressed?).to be true
    end
  end

  describe '#compression_label' do
    it 'returns :raw at start' do
      expect(chunk.compression_label).to eq(:raw)
    end

    it 'changes after compression' do
      10.times { chunk.compress! }
      expect(chunk.compression_label).not_to eq(:raw)
    end
  end

  describe '#fidelity_label' do
    it 'returns :pristine at start' do
      expect(chunk.fidelity_label).to eq(:pristine)
    end
  end

  describe '#to_h' do
    it 'includes all fields' do
      hash = chunk.to_h
      expect(hash).to include(
        :id, :label, :chunk_type, :original_size, :compressed_size,
        :compression_ratio, :compression_label, :fidelity, :fidelity_label,
        :compression_count, :created_at
      )
    end
  end
end
