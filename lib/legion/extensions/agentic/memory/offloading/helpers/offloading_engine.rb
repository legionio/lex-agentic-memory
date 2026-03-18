# frozen_string_literal: true

require_relative 'constants'
require_relative 'external_store'
require_relative 'offloaded_item'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Offloading
          module Helpers
            class OffloadingEngine
              include Constants

              attr_reader :items, :stores

              def initialize
                @items  = {}
                @stores = {}
              end

              def register_store(name:, store_type:)
                return nil if @stores.size >= MAX_STORES

                store = ExternalStore.new(name: name, store_type: store_type)
                @stores[store.id] = store
                store
              end

              def offload(content:, item_type:, importance:, store_id:)
                return nil if @items.size >= MAX_ITEMS
                return nil unless @stores.key?(store_id)

                item = OffloadedItem.new(
                  content:    content,
                  item_type:  item_type,
                  importance: importance,
                  store_id:   store_id
                )
                @items[item.id] = item
                @stores[store_id].increment_items!
                item
              end

              def retrieve(item_id:)
                item = @items[item_id]
                return nil unless item

                store = @stores[item.store_id]
                store&.record_success!
                item.retrieve!
                item
              end

              def retrieve_failed(item_id:)
                item = @items[item_id]
                return nil unless item

                store = @stores[item.store_id]
                store&.record_failure!
                item
              end

              def items_in_store(store_id:)
                @items.values.select { |i| i.store_id == store_id }
              end

              def items_by_type(item_type:)
                @items.values.select { |i| i.item_type == item_type }
              end

              def most_important_offloaded(limit: 10)
                @items.values
                      .sort_by { |i| -i.importance }
                      .first(limit)
              end

              def offloading_ratio
                return 0.0 if MAX_ITEMS.zero?

                (@items.size.to_f / MAX_ITEMS).round(10)
              end

              def overall_store_trust
                return 0.0 if @stores.empty?

                total = @stores.values.sum(&:trust)
                (total / @stores.size).round(10)
              end

              def most_trusted_store
                @stores.values.max_by(&:trust)
              end

              def least_trusted_store
                @stores.values.min_by(&:trust)
              end

              def offloading_report
                {
                  total_items:         @items.size,
                  total_stores:        @stores.size,
                  offloading_ratio:    offloading_ratio,
                  offloading_label:    offloading_label,
                  overall_store_trust: overall_store_trust,
                  most_trusted_store:  most_trusted_store&.to_h,
                  least_trusted_store: least_trusted_store&.to_h,
                  items_by_type:       items_type_summary,
                  stores_summary:      @stores.values.map(&:to_h)
                }
              end

              def to_h
                {
                  items:  @items.transform_values(&:to_h),
                  stores: @stores.transform_values(&:to_h)
                }
              end

              private

              def offloading_label
                OFFLOAD_LABELS.find { |range, _| range.cover?(offloading_ratio) }&.last || :self_reliant
              end

              def items_type_summary
                ITEM_TYPES.to_h do |type|
                  [type, @items.values.count { |i| i.item_type == type }]
                end
              end
            end
          end
        end
      end
    end
  end
end
