# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Compression
          module Helpers
            class CompressionEngine
              include Constants

              def initialize
                @chunks       = {}
                @abstractions = {}
              end

              def store_chunk(label:, chunk_type: :semantic, original_size: 1.0)
                prune_chunks_if_needed
                chunk = InformationChunk.new(label: label, chunk_type: chunk_type,
                                             original_size: original_size)
                @chunks[chunk.id] = chunk
                chunk
              end

              def compress_chunk(chunk_id:, amount: COMPRESSION_RATE)
                chunk = @chunks[chunk_id]
                return nil unless chunk

                chunk.compress!(amount: amount)
              end

              def decompress_chunk(chunk_id:, amount: COMPRESSION_RATE)
                chunk = @chunks[chunk_id]
                return nil unless chunk

                chunk.decompress!(amount: amount)
              end

              def abstract_chunks(chunk_ids:, abstraction_label:)
                prune_abstractions_if_needed
                chunks = chunk_ids.filter_map { |id| @chunks[id] }
                return nil if chunks.empty?

                combined_size = chunks.sum(&:compressed_size)
                abstraction = InformationChunk.new(
                  label:         abstraction_label,
                  chunk_type:    :abstract,
                  original_size: combined_size
                )
                avg_fidelity = (chunks.sum(&:fidelity) / chunks.size).round(10)
                abstraction.compress!(amount: DEFAULT_COMPRESSION_RATIO)
                @abstractions[abstraction.id] = {
                  chunk:      abstraction,
                  source_ids: chunk_ids,
                  fidelity:   avg_fidelity
                }
                abstraction
              end

              def compress_all(amount: COMPRESSION_RATE)
                @chunks.each_value { |c| c.compress!(amount: amount) }
                @chunks.size
              end

              def chunks_by_type(chunk_type:)
                ct = chunk_type.to_sym
                @chunks.values.select { |c| c.chunk_type == ct }
              end

              def highly_compressed_chunks
                @chunks.values.select(&:highly_compressed?)
              end

              def average_compression_ratio
                return 0.0 if @chunks.empty?

                ratios = @chunks.values.map(&:compression_ratio)
                (ratios.sum / ratios.size).round(10)
              end

              def average_fidelity
                return 1.0 if @chunks.empty?

                fids = @chunks.values.map(&:fidelity)
                (fids.sum / fids.size).round(10)
              end

              def total_original_size
                @chunks.values.sum(&:original_size).round(10)
              end

              def total_compressed_size
                @chunks.values.sum(&:compressed_size).round(10)
              end

              def overall_compression_ratio
                return 0.0 if total_original_size.zero?

                (1.0 - (total_compressed_size / total_original_size)).clamp(0.0, 1.0).round(10)
              end

              def compression_report
                {
                  total_chunks:              @chunks.size,
                  total_abstractions:        @abstractions.size,
                  average_compression_ratio: average_compression_ratio,
                  overall_compression_ratio: overall_compression_ratio,
                  average_fidelity:          average_fidelity,
                  total_original_size:       total_original_size,
                  total_compressed_size:     total_compressed_size,
                  highly_compressed_count:   highly_compressed_chunks.size
                }
              end

              def to_h
                {
                  total_chunks:              @chunks.size,
                  total_abstractions:        @abstractions.size,
                  average_compression_ratio: average_compression_ratio,
                  average_fidelity:          average_fidelity
                }
              end

              private

              def prune_chunks_if_needed
                return if @chunks.size < MAX_CHUNKS

                oldest = @chunks.values.min_by(&:created_at)
                @chunks.delete(oldest.id) if oldest
              end

              def prune_abstractions_if_needed
                return if @abstractions.size < MAX_ABSTRACTIONS

                oldest_key = @abstractions.min_by { |_, v| v[:chunk].created_at }&.first
                @abstractions.delete(oldest_key) if oldest_key
              end
            end
          end
        end
      end
    end
  end
end
