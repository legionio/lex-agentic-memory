# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Nostalgia
          module Helpers
            module Constants
              MAX_MEMORIES       = 300
              MAX_EVENTS         = 500
              DEFAULT_WARMTH     = 0.3
              WARMTH_GROWTH      = 0.02
              WARMTH_CEILING     = 0.95
              WARMTH_DECAY       = 0.01
              TRIGGER_SENSITIVITY = 0.3
              ROSY_THRESHOLD = 0.6
              BITTERSWEET_THRESHOLD = 0.5

              MEMORY_DOMAINS = %i[
                relationship
                place
                achievement
                routine
                season
                collaboration
                challenge
                unknown
              ].freeze

              WARMTH_LABELS = {
                0.0..0.2 => :faint,
                0.2..0.4 => :mild,
                0.4..0.6 => :warm,
                0.6..0.8 => :tender,
                0.8..1.0 => :glowing
              }.freeze

              NOSTALGIA_LABELS = {
                0.0..0.2 => :absent,
                0.2..0.4 => :latent,
                0.4..0.6 => :stirring,
                0.6..0.8 => :vivid,
                0.8..1.0 => :overwhelming
              }.freeze

              RETROSPECTION_LABELS = {
                0.0..0.2 => :accurate,
                0.2..0.4 => :slightly_rose_tinted,
                0.4..0.6 => :moderately_rose_tinted,
                0.6..0.8 => :strongly_rose_tinted,
                0.8..1.0 => :heavily_idealized
              }.freeze

              def self.label_for(labels_hash, value)
                clamped = value.clamp(0.0, 1.0)
                labels_hash.each do |range, label|
                  return label if range.cover?(clamped)
                end
                labels_hash.values.last
              end
            end
          end
        end
      end
    end
  end
end
