# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Paleontology
          module Helpers
            class PaleontologyEngine
              def initialize
                @fossils      = {}
                @excavations  = {}
                @extinction_log = []
              end

              def record_extinction(fossil_type:, domain:, content:,
                                    extinction_cause:, stratum_depth: 0,
                                    significance: nil, **)
                validate_capacity!(:fossils, Constants::MAX_FOSSILS)
                fossil = Fossil.new(
                  fossil_type:      fossil_type,
                  domain:           domain,
                  content:          content,
                  extinction_cause: extinction_cause,
                  stratum_depth:    stratum_depth,
                  significance:     significance
                )
                @fossils[fossil.id] = fossil
                @extinction_log << { fossil_id: fossil.id, at: Time.now.utc }
                fossil
              end

              def begin_excavation(target_stratum:)
                validate_capacity!(:excavations, Constants::MAX_EXCAVATIONS)
                exc = Excavation.new(target_stratum: target_stratum)
                @excavations[exc.id] = exc
                exc
              end

              def excavate!(excavation_id:)
                exc = fetch_excavation!(excavation_id)
                raise ArgumentError, 'excavation already completed' if exc.completed?

                matching = stratum_fossils(exc.target_stratum)
                return nil if matching.empty?

                fossil = matching.sample
                exc.record_find!(fossil)
                fossil
              end

              def complete_excavation(excavation_id:)
                exc = fetch_excavation!(excavation_id)
                exc.complete!
                exc
              end

              def erode_all!(rate: Constants::FOSSILIZATION_RATE)
                @fossils.each_value { |f| f.erode!(rate: rate) }
                prune_imprints!
                @fossils.size
              end

              def link_lineage(fossil_id:, ancestor_id:)
                fossil = fetch_fossil!(fossil_id)
                fetch_fossil!(ancestor_id)
                fossil.link_lineage(ancestor_id)
                fossil
              end

              def fossils_by_type(fossil_type)
                @fossils.values.select { |f| f.fossil_type == fossil_type.to_sym }
              end

              def fossils_by_cause(cause)
                @fossils.values.select { |f| f.extinction_cause == cause.to_sym }
              end

              def fossils_by_era(era)
                @fossils.values.select { |f| f.era == era.to_sym }
              end

              def keystone_fossils(limit: 10)
                @fossils.values
                        .select(&:keystone?)
                        .sort_by { |f| -f.significance }
                        .first(limit)
              end

              def extinction_timeline
                @extinction_log.sort_by { |e| e[:at] }
              end

              def mass_extinction?(threshold: 5, window: 60)
                cutoff = Time.now.utc - window
                recent = @extinction_log.count { |e| e[:at] >= cutoff }
                recent >= threshold
              end

              def all_fossils
                @fossils.values
              end

              def all_excavations
                @excavations.values
              end

              def paleontology_report
                {
                  total_fossils:     @fossils.size,
                  total_excavations: @excavations.size,
                  type_breakdown:    count_by(:fossil_type, Constants::FOSSIL_TYPES),
                  cause_breakdown:   count_by(:extinction_cause, Constants::EXTINCTION_CAUSES),
                  era_breakdown:     count_by(:era, Constants::ERA_NAMES),
                  avg_preservation:  avg_field(:preservation),
                  avg_significance:  avg_field(:significance),
                  keystone_count:    @fossils.values.count(&:keystone?),
                  imprint_count:     @fossils.values.count(&:imprint?),
                  ancient_count:     @fossils.values.count(&:ancient?),
                  mass_extinction:   mass_extinction?
                }
              end

              private

              def fetch_fossil!(id)
                @fossils.fetch(id) do
                  raise ArgumentError, "fossil not found: #{id.inspect}"
                end
              end

              def fetch_excavation!(id)
                @excavations.fetch(id) do
                  raise ArgumentError, "excavation not found: #{id.inspect}"
                end
              end

              def validate_capacity!(type, max)
                collection = type == :fossils ? @fossils : @excavations
                return if collection.size < max

                raise ArgumentError, "#{type} capacity reached (max #{max})"
              end

              def stratum_fossils(depth)
                @fossils.values.select { |f| f.stratum_depth == depth }
              end

              def prune_imprints!
                @fossils.delete_if { |_, f| f.preservation <= 0.0 }
              end

              def count_by(attr, values)
                values.to_h do |v|
                  [v, @fossils.values.count { |f| f.public_send(attr) == v }]
                end
              end

              def avg_field(field)
                return 0.0 if @fossils.empty?

                (@fossils.values.sum(&field) / @fossils.size).round(10)
              end
            end
          end
        end
      end
    end
  end
end
