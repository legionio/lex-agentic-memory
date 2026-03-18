# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Semantic
          module Helpers
            module Constants
              MAX_CONCEPTS = 500
              MAX_RELATIONS_PER_CONCEPT = 50
              MAX_HISTORY = 200

              # Relation types between concepts
              RELATION_TYPES = %i[
                is_a has_a part_of
                property_of used_for
                causes prevents
                similar_to opposite_of
                instance_of category_of
              ].freeze

              # Confidence thresholds
              DEFAULT_CONFIDENCE = 0.5
              CONFIDENCE_FLOOR = 0.05
              CONFIDENCE_DECAY = 0.005
              CONFIDENCE_ALPHA = 0.12

              # Access frequency tracking
              ACCESS_BOOST = 0.05
              ACCESS_DECAY = 0.01

              # Retrieval spreading activation
              SPREAD_FACTOR = 0.6
              MAX_SPREAD_HOPS = 3
              SPREAD_THRESHOLD = 0.1

              CONFIDENCE_LABELS = {
                (0.8..)     => :established,
                (0.6...0.8) => :reliable,
                (0.4...0.6) => :provisional,
                (0.2...0.4) => :tentative,
                (..0.2)     => :uncertain
              }.freeze
            end
          end
        end
      end
    end
  end
end
