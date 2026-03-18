# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module SourceMonitoring
          module Helpers
            module Constants
              MAX_RECORDS       = 500
              MAX_HISTORY       = 200
              MAX_ATTRIBUTIONS  = 100

              CONFIDENCE_FLOOR  = 0.1
              CONFIDENCE_DECAY  = 0.01
              CONFIDENCE_ALPHA  = 0.12

              DEFAULT_CONFIDENCE = 0.6

              # Source categories (Johnson & Raye reality monitoring)
              SOURCES = %i[
                external_perception
                internal_generation
                memory_retrieval
                imagination
                inference
                instruction
                dream
                unknown
              ].freeze

              # Reality status — is this from the real world or internally generated?
              REALITY_STATUS = {
                external_perception: :real,
                internal_generation: :constructed,
                memory_retrieval:    :recalled,
                imagination:         :imagined,
                inference:           :derived,
                instruction:         :received,
                dream:               :dreamed,
                unknown:             :uncertain
              }.freeze

              # Confusion pairs — common source monitoring errors
              CONFUSION_PAIRS = [
                %i[external_perception memory_retrieval],
                %i[internal_generation memory_retrieval],
                %i[imagination external_perception],
                %i[inference external_perception],
                %i[dream memory_retrieval]
              ].freeze

              CONFIDENCE_LABELS = {
                (0.8..)     => :certain,
                (0.6...0.8) => :confident,
                (0.4...0.6) => :uncertain,
                (0.2...0.4) => :doubtful,
                (..0.2)     => :guessing
              }.freeze
            end
          end
        end
      end
    end
  end
end
