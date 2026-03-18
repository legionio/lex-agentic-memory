# frozen_string_literal: true

require 'securerandom'
require 'time'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Palimpsest
          module Helpers
            class Palimpsest
              include Constants

              attr_reader :id, :topic, :domain, :current_layer, :historical_layers,
                          :created_at, :overwrite_count

              def initialize(topic:, domain: :unknown)
                @id                = ::SecureRandom.uuid
                @topic             = topic
                @domain            = domain
                @current_layer     = nil
                @historical_layers = []
                @created_at        = ::Time.now.utc
                @overwrite_count   = 0
                @version_counter   = 0
              end

              def overwrite!(new_content, confidence: DEFAULT_CONFIDENCE, author: :system)
                return false if at_layer_limit?

                @version_counter += 1
                new_layer = BeliefLayer.new(
                  content:    new_content,
                  confidence: confidence,
                  domain:     @domain,
                  version:    @version_counter,
                  author:     author
                )

                if @current_layer
                  @current_layer.supersede!(new_layer.id)
                  @historical_layers << @current_layer
                end

                @current_layer = new_layer
                @overwrite_count += 1
                new_layer
              end

              def peek_through(depth: 1)
                return [] if @historical_layers.empty?

                @historical_layers.last([depth, @historical_layers.size].min).reverse
              end

              def erode_current!(rate: EROSION_RATE)
                return nil unless @current_layer

                @current_layer.erode!(rate: rate)
                @current_layer.confidence
              end

              def ghost_layers
                @historical_layers.select(&:ghost?)
              end

              def all_layers
                layers = @historical_layers.dup
                layers << @current_layer if @current_layer
                layers
              end

              def restoration_strength
                ghosts = ghost_layers
                return 0.0 if ghosts.empty?

                total = ghosts.sum(&:confidence)
                (total / ghosts.size).round(10)
              end

              def belief_drift
                return 0.0 unless @current_layer && @historical_layers.any?

                origin = @historical_layers.first
                (@current_layer.confidence - origin.confidence).abs.round(10)
              end

              def drift_label
                Constants.label_for(DRIFT_LABELS, belief_drift)
              end

              def decay_ghosts!(rate: GHOST_DECAY)
                @historical_layers.each { |layer| layer.erode!(rate: rate) if layer.superseded? }
              end

              def to_h
                {
                  id:                   @id,
                  topic:                @topic,
                  domain:               @domain,
                  layer_count:          all_layers.size,
                  overwrite_count:      @overwrite_count,
                  ghost_count:          ghost_layers.size,
                  restoration_strength: restoration_strength.round(4),
                  belief_drift:         belief_drift.round(4),
                  drift_label:          drift_label,
                  current_layer:        @current_layer&.to_h,
                  created_at:           @created_at.iso8601
                }
              end

              private

              def at_layer_limit?
                all_layers.size >= MAX_LAYERS_PER_TOPIC
              end
            end
          end
        end
      end
    end
  end
end
