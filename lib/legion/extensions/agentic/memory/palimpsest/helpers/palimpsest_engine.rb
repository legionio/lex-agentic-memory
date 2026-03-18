# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Palimpsest
          module Helpers
            class PalimpsestEngine
              include Constants

              attr_reader :palimpsests

              def initialize
                @palimpsests = {}
              end

              def create(topic:, domain: :unknown)
                return nil if @palimpsests.size >= MAX_PALIMPSESTS
                return nil if @palimpsests.key?(topic)

                p = Palimpsest.new(topic: topic, domain: domain)
                @palimpsests[topic] = p
                p
              end

              def overwrite(topic:, content:, confidence: DEFAULT_CONFIDENCE, author: :system)
                p = find_or_create(topic)
                return nil unless p

                p.overwrite!(content, confidence: confidence, author: author)
              end

              def peek_through(topic:, depth: 1)
                p = @palimpsests[topic]
                return [] unless p

                p.peek_through(depth: depth).map(&:to_h)
              end

              def erode(topic:, rate: EROSION_RATE)
                p = @palimpsests[topic]
                return nil unless p

                p.erode_current!(rate: rate)
              end

              def ghost_layers_for(topic:)
                p = @palimpsests[topic]
                return [] unless p

                p.ghost_layers.map(&:to_h)
              end

              def all_ghost_layers
                @palimpsests.flat_map { |_topic, p| p.ghost_layers.map(&:to_h) }
              end

              def domain_archaeology(domain:)
                @palimpsests.each_with_object([]) do |(_topic, p), results|
                  next unless p.domain == domain

                  p.all_layers.each { |layer| results << layer.to_h.merge(topic: p.topic) }
                end
              end

              def belief_drift(topic:)
                p = @palimpsests[topic]
                return nil unless p

                { drift: p.belief_drift.round(4), label: p.drift_label }
              end

              def overwrite_frequency(topic:)
                p = @palimpsests[topic]
                return nil unless p

                p.overwrite_count
              end

              def most_rewritten(limit: 10)
                sorted = @palimpsests.values.sort_by { |p| -p.overwrite_count }
                sorted.first(limit).map(&:to_h)
              end

              def decay_all!(ghost_rate: GHOST_DECAY)
                @palimpsests.each_value { |p| p.decay_ghosts!(rate: ghost_rate) }
              end

              def palimpsest_report
                total_ghosts = @palimpsests.values.sum { |p| p.ghost_layers.size }
                avg_drift    = if @palimpsests.empty?
                                 0.0
                               else
                                 total = @palimpsests.values.sum(&:belief_drift)
                                 (total / @palimpsests.size).round(4)
                               end
                {
                  palimpsest_count: @palimpsests.size,
                  total_ghosts:     total_ghosts,
                  average_drift:    avg_drift,
                  most_rewritten:   most_rewritten(limit: 5)
                }
              end

              private

              def find_or_create(topic)
                @palimpsests[topic] || create(topic: topic)
              end
            end
          end
        end
      end
    end
  end
end
