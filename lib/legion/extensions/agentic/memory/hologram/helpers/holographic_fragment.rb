# frozen_string_literal: true

require 'securerandom'
require 'time'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Hologram
          module Helpers
            class HolographicFragment
              include Constants

              attr_reader :id, :parent_hologram_id, :content, :created_at
              attr_accessor :completeness, :fidelity

              def initialize(content:, parent_hologram_id:, completeness: 1.0, fidelity: 1.0)
                @id                = SecureRandom.uuid
                @content           = content
                @parent_hologram_id = parent_hologram_id
                @completeness      = completeness.clamp(0.0, 1.0)
                @fidelity          = fidelity.clamp(0.0, 1.0)
                @created_at        = Time.now.utc
              end

              def degrade!(rate = Constants::INTERFERENCE_DECAY)
                @completeness = (@completeness - rate).round(10).clamp(0.0, 1.0)
                @fidelity     = (@fidelity - rate).round(10).clamp(0.0, 1.0)
                self
              end

              def enhance!(boost = 0.1)
                @completeness = (@completeness + boost).round(10).clamp(0.0, 1.0)
                @fidelity     = (@fidelity + boost).round(10).clamp(0.0, 1.0)
                self
              end

              def sufficient?
                @completeness > Constants::RECONSTRUCTION_THRESHOLD
              end

              def completeness_label
                Constants.label_for(Constants::FRAGMENT_LABELS, @completeness)
              end

              def fidelity_label
                Constants.label_for(Constants::FIDELITY_LABELS, @fidelity)
              end

              def to_h
                {
                  id:                 @id,
                  parent_hologram_id: @parent_hologram_id,
                  content:            @content,
                  completeness:       @completeness,
                  fidelity:           @fidelity,
                  completeness_label: completeness_label,
                  fidelity_label:     fidelity_label,
                  sufficient:         sufficient?,
                  created_at:         @created_at.iso8601
                }
              end
            end
          end
        end
      end
    end
  end
end
