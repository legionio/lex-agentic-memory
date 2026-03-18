# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Archaeology
          module Helpers
            module Constants
              MAX_ARTIFACTS            = 500
              MAX_SITES                = 50
              DEFAULT_PRESERVATION     = 0.5
              PRESERVATION_DECAY       = 0.02
              SEDIMENT_DENSITY_DEFAULT = 0.5

              ARTIFACT_TYPES = %i[
                pattern skill knowledge memory_fragment
                association procedure belief schema
              ].freeze

              DOMAIN_TYPES = %i[
                cognitive emotional procedural semantic
                episodic social creative analytical
              ].freeze

              EXCAVATION_DEPTH_LEVELS = %i[surface shallow mid deep bedrock].freeze

              EPOCH_NAMES = %i[
                genesis formation expansion consolidation
                crisis renewal maturation current
              ].freeze

              DEPTH_PRESERVATION_MODIFIER = {
                surface: 0.0,
                shallow: -0.1,
                mid:     -0.2,
                deep:    -0.35,
                bedrock: -0.5
              }.freeze

              DEPTH_RARITY_WEIGHTS = {
                surface: { pattern: 3, skill: 2, knowledge: 3, memory_fragment: 5,
                           association: 3, procedure: 2, belief: 1, schema: 1 },
                shallow: { pattern: 3, skill: 3, knowledge: 3, memory_fragment: 4,
                           association: 3, procedure: 3, belief: 1, schema: 1 },
                mid:     { pattern: 2, skill: 3, knowledge: 3, memory_fragment: 3,
                           association: 3, procedure: 3, belief: 2, schema: 2 },
                deep:    { pattern: 1, skill: 2, knowledge: 2, memory_fragment: 2,
                           association: 2, procedure: 3, belief: 3, schema: 3 },
                bedrock: { pattern: 1, skill: 1, knowledge: 1, memory_fragment: 1,
                           association: 1, procedure: 2, belief: 4, schema: 4 }
              }.freeze

              PRESERVATION_LABELS = [
                [0.0..0.2, :dust],
                [0.2..0.4, :fragmented],
                [0.4..0.6, :partial],
                [0.6..0.8, :intact],
                [0.8..1.0, :pristine]
              ].freeze

              INTEGRITY_LABELS = [
                [0.0..0.3, :corrupted],
                [0.3..0.6, :degraded],
                [0.6..0.8, :coherent],
                [0.8..1.0, :complete]
              ].freeze

              DENSITY_LABELS = [
                [0.0..0.2, :friable],
                [0.2..0.4, :loose],
                [0.4..0.6, :moderate],
                [0.6..0.8, :dense],
                [0.8..1.0, :compacted]
              ].freeze

              DEPTH_LABELS = {
                surface: 'Surface Layer (recent, well-preserved)',
                shallow: 'Shallow Layer (familiar but fading)',
                mid:     'Mid Layer (semi-dormant knowledge)',
                deep:    'Deep Layer (long-dormant patterns)',
                bedrock: 'Bedrock Layer (foundational cognitive strata)'
              }.freeze

              def self.label_for(table, value)
                table.each { |range, label| return label if range.cover?(value) }
                table.last.last
              end
            end
          end
        end
      end
    end
  end
end
