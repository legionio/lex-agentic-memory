# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Compression
          module Helpers
            class InformationChunk
              include Constants

              attr_reader :id, :label, :chunk_type, :original_size, :compressed_size,
                          :fidelity, :compression_count, :created_at

              def initialize(label:, chunk_type: :semantic, original_size: 1.0)
                @id                = SecureRandom.uuid
                @label             = label
                @chunk_type        = chunk_type.to_sym
                @original_size     = [original_size.to_f, 0.01].max
                @compressed_size   = @original_size
                @fidelity          = 1.0
                @compression_count = 0
                @created_at        = Time.now.utc
              end

              def compression_ratio
                return 0.0 if @original_size.zero?

                (1.0 - (@compressed_size / @original_size)).clamp(0.0, 1.0).round(10)
              end

              def compress!(amount: COMPRESSION_RATE)
                @compressed_size = (@compressed_size * (1.0 - amount)).clamp(0.01, @original_size).round(10)
                @fidelity = (@fidelity - FIDELITY_LOSS_RATE).clamp(MIN_FIDELITY, 1.0).round(10)
                @compression_count += 1
                self
              end

              def decompress!(amount: COMPRESSION_RATE)
                @compressed_size = (@compressed_size / (1.0 - amount)).clamp(0.01, @original_size).round(10)
                self
              end

              def highly_compressed?
                compression_ratio >= 0.8
              end

              def compression_label
                match = COMPRESSION_LABELS.find { |range, _| range.cover?(compression_ratio) }
                match ? match.last : :raw
              end

              def fidelity_label
                match = FIDELITY_LABELS.find { |range, _| range.cover?(@fidelity) }
                match ? match.last : :degraded
              end

              def to_h
                {
                  id:                @id,
                  label:             @label,
                  chunk_type:        @chunk_type,
                  original_size:     @original_size,
                  compressed_size:   @compressed_size,
                  compression_ratio: compression_ratio,
                  compression_label: compression_label,
                  fidelity:          @fidelity,
                  fidelity_label:    fidelity_label,
                  compression_count: @compression_count,
                  created_at:        @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
