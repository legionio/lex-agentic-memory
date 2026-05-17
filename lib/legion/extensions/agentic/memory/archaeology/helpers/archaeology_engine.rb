# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Archaeology
          module Helpers
            class ArchaeologyEngine
              def initialize
                @sites     = {}
                @artifacts = {}
              end

              def create_site(domain:)
                validate_site_capacity!
                site = ExcavationSite.new(domain: domain)
                @sites[site.id] = site
                site
              end

              def dig(site_id:)
                site = fetch_site!(site_id)
                dug  = site.dig_deeper!
                { site: site.survey, dug: dug }
              end

              def excavate(site_id:)
                site = fetch_site!(site_id)
                validate_artifact_capacity!
                artifact = site.excavate!
                @artifacts[artifact.id] = artifact
                artifact
              end

              def restore_artifact(artifact_id:, boost: 0.15)
                artifact = fetch_artifact!(artifact_id)
                artifact.restore!(boost: boost)
                artifact
              end

              def decay_all!(rate: Constants::PRESERVATION_DECAY)
                @artifacts.each_value { |a| a.decay!(rate: rate) }
                prune_dust!
                @artifacts.size
              end

              def artifacts_by_type(type)
                @artifacts.values.select { |a| a.artifact_type == type.to_sym }
              end

              def artifacts_by_domain(domain)
                @artifacts.values.select { |a| a.domain == domain.to_sym }
              end

              def artifacts_by_depth(depth_level)
                @artifacts.values.select do |a|
                  a.depth_level == depth_level.to_sym
                end
              end

              def best_preserved(limit: 10)
                @artifacts.values.sort_by { |a| -a.preservation }.first(limit)
              end

              def most_fragile(limit: 10)
                @artifacts.values
                          .select(&:fragment?)
                          .sort_by(&:preservation)
                          .first(limit)
              end

              def site_report(site_id:)
                fetch_site!(site_id).to_h
              end

              def archaeology_report
                {
                  total_artifacts:  @artifacts.size,
                  total_sites:      @sites.size,
                  type_breakdown:   type_breakdown,
                  domain_breakdown: domain_breakdown,
                  depth_breakdown:  depth_breakdown,
                  avg_preservation: avg_preservation,
                  avg_integrity:    avg_integrity,
                  fragment_count:   @artifacts.values.count(&:fragment?),
                  ancient_count:    @artifacts.values.count(&:ancient?),
                  sites:            @sites.values.map { |s| site_summary(s) }
                }
              end

              def all_artifacts
                @artifacts.values
              end

              def all_sites
                @sites.values
              end

              private

              def fetch_site!(site_id)
                @sites.fetch(site_id) do
                  raise ArgumentError, "site not found: #{site_id.inspect}"
                end
              end

              def fetch_artifact!(artifact_id)
                @artifacts.fetch(artifact_id) do
                  raise ArgumentError,
                        "artifact not found: #{artifact_id.inspect}"
                end
              end

              def validate_site_capacity!
                return if @sites.size < Constants::MAX_SITES

                raise ArgumentError,
                      "site capacity reached (max #{Constants::MAX_SITES})"
              end

              def validate_artifact_capacity!
                return if @artifacts.size < Constants::MAX_ARTIFACTS

                raise ArgumentError,
                      "artifact capacity reached (max #{Constants::MAX_ARTIFACTS})"
              end

              def prune_dust!
                @artifacts.delete_if { |_, a| a.preservation <= 0.0 }
              end

              def type_breakdown
                count_by(:artifact_type, Constants::ARTIFACT_TYPES)
              end

              def domain_breakdown
                count_by(:domain, Constants::DOMAIN_TYPES)
              end

              def depth_breakdown
                count_by(:depth_level, Constants::EXCAVATION_DEPTH_LEVELS)
              end

              def count_by(attr, values)
                values.to_h do |v|
                  [v, @artifacts.values.count { |a| a.public_send(attr) == v }]
                end
              end

              def avg_preservation
                return 0.0 if @artifacts.empty?

                (@artifacts.values.sum(&:preservation) / @artifacts.size).round(10)
              end

              def avg_integrity
                return 0.0 if @artifacts.empty?

                (@artifacts.values.sum(&:integrity) / @artifacts.size).round(10)
              end

              def site_summary(site)
                site.survey.merge(
                  depth_progress: depth_progress(site),
                  artifact_types: site.artifacts_found
                                  .each_with_object(Hash.new(0)) do |a, h|
                                    h[a.artifact_type] += 1
                                  end
                )
              end

              def depth_progress(site)
                idx   = Constants::EXCAVATION_DEPTH_LEVELS.index(site.current_depth)
                total = Constants::EXCAVATION_DEPTH_LEVELS.size - 1
                total.zero? ? 1.0 : (idx.to_f / total).round(4)
              end
            end
          end
        end
      end
    end
  end
end
