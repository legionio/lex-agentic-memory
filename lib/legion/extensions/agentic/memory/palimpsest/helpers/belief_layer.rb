# frozen_string_literal: true

require 'securerandom'
require 'time'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Palimpsest
          module Helpers
            class BeliefLayer
              include Constants

              attr_reader :id, :content, :confidence, :domain, :version, :author,
                          :timestamp, :superseded_by

              def initialize(content:, confidence: DEFAULT_CONFIDENCE, domain: :unknown,
                             version: 1, author: :system)
                @id            = ::SecureRandom.uuid
                @content       = content
                @confidence    = confidence.to_f.clamp(0.0, 1.0)
                @domain        = domain
                @version       = version
                @author        = author
                @timestamp     = ::Time.now.utc
                @superseded_by = nil
              end

              def supersede!(next_layer_id)
                @superseded_by = next_layer_id
              end

              def superseded?
                !@superseded_by.nil?
              end

              def ghost?
                superseded? && @confidence > GHOST_THRESHOLD
              end

              def dissipated?
                superseded? && @confidence <= GHOST_THRESHOLD
              end

              def erode!(rate: EROSION_RATE)
                @confidence = (@confidence - rate).clamp(0.0, 1.0).round(10)
              end

              def confidence_label
                Constants.label_for(CONFIDENCE_LABELS, @confidence)
              end

              def ghost_label
                return :not_ghost unless superseded?

                Constants.label_for(GHOST_LABELS, @confidence)
              end

              def to_h
                {
                  id:            @id,
                  content:       @content,
                  confidence:    @confidence.round(4),
                  domain:        @domain,
                  version:       @version,
                  author:        @author,
                  timestamp:     @timestamp.iso8601,
                  superseded_by: @superseded_by,
                  superseded:    superseded?,
                  ghost:         ghost?,
                  label:         confidence_label
                }
              end
            end
          end
        end
      end
    end
  end
end
