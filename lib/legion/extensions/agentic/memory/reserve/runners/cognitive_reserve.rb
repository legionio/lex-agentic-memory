# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Reserve
          module Runners
            module CognitiveReserve
              include Helpers::Constants
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def add_cognitive_pathway(function:, domain: :general, capacity: DEFAULT_CAPACITY, **)
                pathway = engine.add_pathway(function: function, domain: domain, capacity: capacity)
                return { success: false, reason: :limit_reached } unless pathway

                { success: true, pathway_id: pathway.id, capacity: pathway.capacity }
              end

              def link_backup_pathway(primary_id:, backup_id:, **)
                result = engine.link_backup(primary_id: primary_id, backup_id: backup_id)
                return { success: false, reason: :not_found } unless result

                { success: true, primary_id: primary_id, backup_id: backup_id, backup_count: result.backup_ids.size }
              end

              def damage_cognitive_pathway(pathway_id:, amount:, **)
                pathway = engine.damage_pathway(pathway_id: pathway_id, amount: amount)
                return { success: false, reason: :not_found } unless pathway

                {
                  success:            true,
                  pathway_id:         pathway_id,
                  capacity:           pathway.capacity.round(4),
                  state:              pathway.state,
                  effective_capacity: engine.effective_capacity(pathway_id: pathway_id)&.round(4)
                }
              end

              def recover_cognitive_pathway(pathway_id:, amount: RECOVERY_RATE, **)
                pathway = engine.recover_pathway(pathway_id: pathway_id, amount: amount)
                return { success: false, reason: :not_found } unless pathway

                { success: true, pathway_id: pathway_id, capacity: pathway.capacity.round(4), state: pathway.state }
              end

              def cognitive_reserve_assessment(**)
                {
                  success:         true,
                  overall_reserve: engine.overall_reserve.round(4),
                  reserve_label:   engine.reserve_label,
                  most_vulnerable: engine.most_vulnerable,
                  degraded:        engine.degraded_pathways,
                  failed:          engine.failed_pathways
                }
              end

              def domain_cognitive_reserve(domain:, **)
                {
                  success:       true,
                  domain:        domain,
                  reserve:       engine.domain_reserve(domain: domain).round(4),
                  pathway_count: engine.pathways.values.count { |p| p.domain == domain }
                }
              end

              def most_redundant_pathways(**)
                pathways = engine.most_redundant
                { success: true, pathways: pathways, count: pathways.size }
              end

              def update_cognitive_reserve(**)
                engine.recover_all
                { success: true }.merge(engine.to_h)
              end

              def cognitive_reserve_stats(**)
                { success: true }.merge(engine.to_h)
              end

              private

              def engine
                @engine ||= Helpers::ReserveEngine.new
              end
            end
          end
        end
      end
    end
  end
end
