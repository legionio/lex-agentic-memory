# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Compression::Helpers::Constants do
  let(:klass) { Class.new { include Legion::Extensions::Agentic::Memory::Compression::Helpers::Constants } }

  describe 'COMPRESSION_LABELS' do
    it 'is a frozen hash' do
      expect(klass::COMPRESSION_LABELS).to be_a(Hash).and be_frozen
    end

    it 'covers the full 0..1 range' do
      labels = klass::COMPRESSION_LABELS
      [0.0, 0.3, 0.5, 0.7, 0.9].each do |val|
        match = labels.find { |range, _| range.cover?(val) }
        expect(match).not_to be_nil, "no label for #{val}"
      end
    end
  end

  describe 'FIDELITY_LABELS' do
    it 'is a frozen hash' do
      expect(klass::FIDELITY_LABELS).to be_a(Hash).and be_frozen
    end
  end

  describe 'CHUNK_TYPES' do
    it 'is a frozen array of symbols' do
      expect(klass::CHUNK_TYPES).to be_a(Array).and be_frozen
      expect(klass::CHUNK_TYPES).to all(be_a(Symbol))
    end

    it 'includes semantic and episodic' do
      expect(klass::CHUNK_TYPES).to include(:semantic, :episodic)
    end
  end

  describe 'numeric constants' do
    it 'has positive MAX_CHUNKS' do
      expect(klass::MAX_CHUNKS).to be > 0
    end

    it 'has COMPRESSION_RATE between 0 and 1' do
      expect(klass::COMPRESSION_RATE).to be_between(0.0, 1.0)
    end

    it 'has MIN_FIDELITY between 0 and 1' do
      expect(klass::MIN_FIDELITY).to be_between(0.0, 1.0)
    end
  end
end
