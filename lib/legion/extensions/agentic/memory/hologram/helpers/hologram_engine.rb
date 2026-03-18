# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Hologram
          module Helpers
            class HologramEngine
              include Constants

              def initialize
                @holograms = {}
              end

              def create_hologram(domain:, content:)
                prune! if @holograms.size >= Constants::MAX_HOLOGRAMS

                hologram = Hologram.new(domain: domain, content: content)
                @holograms[hologram.id] = hologram
                hologram
              end

              def fragment_hologram(hologram_id:, count: 4)
                hologram = @holograms[hologram_id]
                return nil unless hologram

                hologram.fragment!(count)
              end

              def reconstruct_from_fragments(fragment_ids:, hologram_id:)
                hologram = @holograms[hologram_id]
                return { success: false, reason: :hologram_not_found } unless hologram

                fragments = hologram.fragments.select { |f| fragment_ids.include?(f.id) }
                hologram.reconstruct(fragments)
              end

              def measure_interference(hologram_id_a:, hologram_id_b:)
                holo_a = @holograms[hologram_id_a]
                holo_b = @holograms[hologram_id_b]

                return { interference: 0.0, label: :negligible, reason: :hologram_not_found } unless holo_a && holo_b

                score = holo_a.interference_with(holo_b)
                {
                  interference: score,
                  label:        Constants.label_for(Constants::INTERFERENCE_LABELS, score),
                  hologram_a:   hologram_id_a,
                  hologram_b:   hologram_id_b
                }
              end

              def degrade_all!
                @holograms.each_value do |hologram|
                  hologram.fragments.each(&:degrade!)
                end
              end

              def best_preserved(limit: 5)
                @holograms.values
                          .select { |h| h.fragments.any? }
                          .sort_by { |h| -h.resolution }
                          .first(limit)
              end

              def most_fragmented(limit: 5)
                @holograms.values
                          .select { |h| h.fragments.any? }
                          .sort_by(&:resolution)
                          .first(limit)
              end

              def hologram_report
                total = @holograms.size
                with_fragments = @holograms.values.count { |h| h.fragments.any? }
                avg_resolution = resolution_average

                {
                  total_holograms:       total,
                  holograms_with_frags:  with_fragments,
                  average_resolution:    avg_resolution,
                  resolution_label:      Constants.label_for(Constants::RESOLUTION_LABELS, avg_resolution),
                  best_preserved_count:  best_preserved(limit: 3).size,
                  most_fragmented_count: most_fragmented(limit: 3).size
                }
              end

              def holograms
                @holograms.values
              end

              def get(hologram_id)
                @holograms[hologram_id]
              end

              private

              def resolution_average
                return 0.0 if @holograms.empty?

                values = @holograms.values.map(&:resolution)
                (values.sum.round(10) / values.size).round(10)
              end

              def prune!
                worst = most_fragmented(limit: 10)
                to_remove = worst.size.positive? ? worst : [@holograms.values.first]
                to_remove.each { |h| @holograms.delete(h.id) }
              end
            end
          end
        end
      end
    end
  end
end
