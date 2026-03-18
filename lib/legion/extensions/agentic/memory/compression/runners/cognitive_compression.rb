# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Compression
          module Runners
            module CognitiveCompression
              include Helpers::Constants

              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def store_chunk(label:, engine: nil, chunk_type: :semantic, original_size: 1.0, **)
                eng = engine || default_engine
                chunk = eng.store_chunk(label: label, chunk_type: chunk_type, original_size: original_size)
                { success: true, chunk: chunk.to_h }
              end

              def compress_chunk(chunk_id:, engine: nil, amount: COMPRESSION_RATE, **)
                eng = engine || default_engine
                result = eng.compress_chunk(chunk_id: chunk_id, amount: amount)
                return { success: false, error: 'chunk not found' } unless result

                { success: true, chunk: result.to_h }
              end

              def decompress_chunk(chunk_id:, engine: nil, amount: COMPRESSION_RATE, **)
                eng = engine || default_engine
                result = eng.decompress_chunk(chunk_id: chunk_id, amount: amount)
                return { success: false, error: 'chunk not found' } unless result

                { success: true, chunk: result.to_h }
              end

              def abstract_chunks(chunk_ids:, abstraction_label:, engine: nil, **)
                eng = engine || default_engine
                result = eng.abstract_chunks(chunk_ids: chunk_ids, abstraction_label: abstraction_label)
                return { success: false, error: 'no valid chunks' } unless result

                { success: true, abstraction: result.to_h }
              end

              def compress_all(engine: nil, amount: COMPRESSION_RATE, **)
                eng = engine || default_engine
                count = eng.compress_all(amount: amount)
                { success: true, compressed_count: count }
              end

              def average_fidelity(engine: nil, **)
                eng = engine || default_engine
                { success: true, fidelity: eng.average_fidelity }
              end

              def overall_compression_ratio(engine: nil, **)
                eng = engine || default_engine
                { success: true, ratio: eng.overall_compression_ratio }
              end

              def compression_report(engine: nil, **)
                eng = engine || default_engine
                { success: true, report: eng.compression_report }
              end

              private

              def default_engine
                @default_engine ||= Helpers::CompressionEngine.new
              end
            end
          end
        end
      end
    end
  end
end
