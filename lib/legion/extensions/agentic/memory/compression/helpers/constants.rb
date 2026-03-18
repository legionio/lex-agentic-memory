# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Compression
          module Helpers
            module Constants
              MAX_CHUNKS = 500
              MAX_ABSTRACTIONS = 200

              DEFAULT_COMPRESSION_RATIO = 0.5
              COMPRESSION_RATE = 0.1
              FIDELITY_LOSS_RATE = 0.02
              MIN_FIDELITY = 0.1

              COMPRESSION_LABELS = {
                (0.8..)     => :highly_compressed,
                (0.6...0.8) => :compressed,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :detailed,
                (..0.2)     => :raw
              }.freeze

              FIDELITY_LABELS = {
                (0.8..)     => :pristine,
                (0.6...0.8) => :faithful,
                (0.4...0.6) => :approximate,
                (0.2...0.4) => :lossy,
                (..0.2)     => :degraded
              }.freeze

              CHUNK_TYPES = %i[
                episodic semantic procedural sensory
                emotional abstract relational
              ].freeze
            end
          end
        end
      end
    end
  end
end
