# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Offloading
          module Runners
            module CognitiveOffloading
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def register_store(name:, store_type:, engine: nil, **)
                eng = engine || offloading_engine
                store = eng.register_store(name: name, store_type: store_type)
                if store
                  log.info("[cognitive_offloading] registered store name=#{name} type=#{store_type} id=#{store.id}")
                  { success: true, store: store.to_h }
                else
                  log.warn('[cognitive_offloading] register_store failed: limit reached or invalid store_type')
                  { success: false, reason: :limit_reached }
                end
              end

              def offload_item(content:, item_type:, importance:, store_id:, engine: nil, **)
                eng = engine || offloading_engine
                item = eng.offload(content: content, item_type: item_type, importance: importance, store_id: store_id)
                if item
                  log.info("[cognitive_offloading] offloaded item=#{item.id} type=#{item_type} importance=#{importance.round(2)} store=#{store_id}")
                  { success: true, item: item.to_h }
                else
                  log.warn("[cognitive_offloading] offload failed: limit reached or store not found store_id=#{store_id}")
                  { success: false, reason: :offload_failed }
                end
              end

              def retrieve_item(item_id:, engine: nil, **)
                eng = engine || offloading_engine
                item = eng.retrieve(item_id: item_id)
                if item
                  log.debug("[cognitive_offloading] retrieved item=#{item_id} count=#{item.retrieved_count}")
                  { success: true, item: item.to_h }
                else
                  log.warn("[cognitive_offloading] retrieve failed: item not found item_id=#{item_id}")
                  { success: false, reason: :not_found }
                end
              end

              def report_retrieval_failure(item_id:, engine: nil, **)
                eng = engine || offloading_engine
                item = eng.retrieve_failed(item_id: item_id)
                if item
                  store = eng.stores[item.store_id]
                  trust = store&.trust&.round(2)
                  log.warn("[cognitive_offloading] retrieval failure item=#{item_id} store_trust=#{trust}")
                  { success: true, item_id: item_id, store_trust: trust }
                else
                  { success: false, reason: :not_found }
                end
              end

              def items_in_store(store_id:, engine: nil, **)
                eng = engine || offloading_engine
                items = eng.items_in_store(store_id: store_id)
                log.debug("[cognitive_offloading] items_in_store store=#{store_id} count=#{items.size}")
                { success: true, items: items.map(&:to_h), count: items.size }
              end

              def items_by_type(item_type:, engine: nil, **)
                eng = engine || offloading_engine
                items = eng.items_by_type(item_type: item_type)
                log.debug("[cognitive_offloading] items_by_type type=#{item_type} count=#{items.size}")
                { success: true, items: items.map(&:to_h), count: items.size }
              end

              def most_important_offloaded(limit: 10, engine: nil, **)
                eng = engine || offloading_engine
                items = eng.most_important_offloaded(limit: limit)
                log.debug("[cognitive_offloading] most_important limit=#{limit} count=#{items.size}")
                { success: true, items: items.map(&:to_h), count: items.size }
              end

              def offloading_status(engine: nil, **)
                eng = engine || offloading_engine
                report = eng.offloading_report
                ratio = report[:offloading_ratio]
                log.debug("[cognitive_offloading] status items=#{report[:total_items]} stores=#{report[:total_stores]} ratio=#{ratio}")
                { success: true, report: report }
              end

              private

              def offloading_engine
                @offloading_engine ||= Helpers::OffloadingEngine.new
              end
            end
          end
        end
      end
    end
  end
end
