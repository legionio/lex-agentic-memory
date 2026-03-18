# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Offloading
          module Helpers
            module Constants
              MAX_ITEMS         = 500
              MAX_STORES        = 50
              DEFAULT_STORE_TRUST = 0.7
              TRUST_DECAY       = 0.02
              TRUST_BOOST       = 0.05

              ITEM_TYPES = %i[
                fact procedure plan context delegation reminder calculation reference
              ].freeze

              STORE_TYPES = %i[
                database file agent tool memory_aid external_service notes
              ].freeze

              TRUST_LABELS = {
                (0.8..)     => :highly_trusted,
                (0.6...0.8) => :trusted,
                (0.4...0.6) => :cautious,
                (0.2...0.4) => :distrusted,
                (..0.2)     => :unreliable
              }.freeze

              IMPORTANCE_LABELS = {
                (0.8..)     => :critical,
                (0.6...0.8) => :important,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :low,
                (..0.2)     => :trivial
              }.freeze

              OFFLOAD_LABELS = {
                (0.8..)     => :heavily_offloaded,
                (0.6...0.8) => :mostly_offloaded,
                (0.4...0.6) => :balanced,
                (0.2...0.4) => :mostly_internal,
                (..0.2)     => :self_reliant
              }.freeze

              RETRIEVAL_SUCCESS_THRESHOLD = 0.7
            end
          end
        end
      end
    end
  end
end
