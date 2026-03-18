# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Reserve
          module Helpers
            class ReserveEngine
              include Constants

              attr_reader :pathways, :history

              def initialize
                @pathways      = {}
                @pathway_count = 0
                @history       = []
              end

              def add_pathway(function:, domain: :general, capacity: DEFAULT_CAPACITY)
                return nil if @pathways.size >= MAX_PATHWAYS

                @pathway_count += 1
                pathway = Pathway.new(
                  id:       :"path_#{@pathway_count}",
                  function: function,
                  domain:   domain,
                  capacity: capacity
                )
                @pathways[pathway.id] = pathway
                record_event(:add_pathway, pathway_id: pathway.id)
                pathway
              end

              def link_backup(primary_id:, backup_id:)
                primary = @pathways[primary_id]
                backup  = @pathways[backup_id]
                return nil unless primary && backup

                primary.add_backup(pathway_id: backup_id)
                record_event(:link_backup, primary_id: primary_id, backup_id: backup_id)
                primary
              end

              def damage_pathway(pathway_id:, amount:)
                pathway = @pathways[pathway_id]
                return nil unless pathway

                pathway.damage(amount: amount)
                activate_compensation(pathway) if pathway.degraded?
                record_event(:damage, pathway_id: pathway_id, amount: amount, state: pathway.state)
                pathway
              end

              def recover_pathway(pathway_id:, amount: RECOVERY_RATE)
                pathway = @pathways[pathway_id]
                return nil unless pathway

                pathway.recover(amount: amount)
                record_event(:recover, pathway_id: pathway_id)
                pathway
              end

              def effective_capacity(pathway_id:)
                pathway = @pathways[pathway_id]
                return nil unless pathway

                backup_caps = pathway.backup_ids.filter_map { |bid| @pathways[bid]&.capacity }
                pathway.effective_capacity(backup_capacities: backup_caps)
              end

              def overall_reserve
                return DEFAULT_CAPACITY if @pathways.empty?

                caps = @pathways.values.map do |p|
                  backup_caps = p.backup_ids.filter_map { |bid| @pathways[bid]&.capacity }
                  p.effective_capacity(backup_capacities: backup_caps)
                end
                caps.sum / caps.size.to_f
              end

              def reserve_label
                ratio = overall_reserve
                RESERVE_LABELS.find { |range, _| range.cover?(ratio) }&.last || :critical
              end

              def degraded_pathways
                @pathways.values.select(&:degraded?).map(&:to_h)
              end

              def failed_pathways
                @pathways.values.select(&:failed?).map(&:to_h)
              end

              def healthy_pathways
                @pathways.values.select(&:healthy?).map(&:to_h)
              end

              def domain_reserve(domain:)
                relevant = @pathways.values.select { |p| p.domain == domain }
                return DEFAULT_CAPACITY if relevant.empty?

                caps = relevant.map do |p|
                  backup_caps = p.backup_ids.filter_map { |bid| @pathways[bid]&.capacity }
                  p.effective_capacity(backup_capacities: backup_caps)
                end
                caps.sum / caps.size.to_f
              end

              def most_vulnerable(limit: 5)
                @pathways.values
                         .sort_by(&:capacity)
                         .first(limit)
                         .map(&:to_h)
              end

              def most_redundant(limit: 5)
                @pathways.values
                         .sort_by { |p| -p.redundancy }
                         .first(limit)
                         .map(&:to_h)
              end

              def recover_all
                @pathways.each_value { |p| p.recover unless p.failed? }
              end

              def to_h
                {
                  pathway_count:   @pathways.size,
                  overall_reserve: overall_reserve.round(4),
                  reserve_label:   reserve_label,
                  healthy_count:   @pathways.values.count(&:healthy?),
                  degraded_count:  @pathways.values.count(&:degraded?),
                  failed_count:    @pathways.values.count(&:failed?),
                  history_size:    @history.size
                }
              end

              private

              def activate_compensation(pathway)
                pathway.backup_ids.each do |backup_id|
                  backup = @pathways[backup_id]
                  next unless backup&.healthy?

                  pathway.compensate!
                  record_event(:compensate, pathway_id: pathway.id, backup_id: backup_id)
                  break
                end
              end

              def record_event(type, **details)
                @history << { type: type, at: Time.now.utc }.merge(details)
                @history.shift while @history.size > MAX_HISTORY
              end
            end
          end
        end
      end
    end
  end
end
