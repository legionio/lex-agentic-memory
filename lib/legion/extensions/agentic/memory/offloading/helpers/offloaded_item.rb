# frozen_string_literal: true

require 'securerandom'
require_relative 'constants'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Offloading
          module Helpers
            class OffloadedItem
              include Constants

              attr_reader :id, :content, :item_type, :importance, :store_id,
                          :offloaded_at, :retrieved_count, :last_retrieved_at

              def initialize(content:, item_type:, importance:, store_id:)
                @id               = ::SecureRandom.uuid
                @content          = content
                @item_type        = item_type
                @importance       = importance.clamp(0.0, 1.0)
                @store_id         = store_id
                @offloaded_at     = Time.now.utc
                @retrieved_count  = 0
                @last_retrieved_at = nil
              end

              def retrieve!
                @retrieved_count  += 1
                @last_retrieved_at = Time.now.utc
                self
              end

              def stale?(threshold_seconds: 3600)
                return false if @last_retrieved_at.nil? && @retrieved_count.zero?

                reference = @last_retrieved_at || @offloaded_at
                (Time.now.utc - reference) > threshold_seconds
              end

              def importance_label
                IMPORTANCE_LABELS.find { |range, _| range.cover?(@importance) }&.last || :trivial
              end

              def to_h
                {
                  id:                @id,
                  content:           @content,
                  item_type:         @item_type,
                  importance:        @importance.round(10),
                  importance_label:  importance_label,
                  store_id:          @store_id,
                  offloaded_at:      @offloaded_at,
                  retrieved_count:   @retrieved_count,
                  last_retrieved_at: @last_retrieved_at
                }
              end
            end
          end
        end
      end
    end
  end
end
