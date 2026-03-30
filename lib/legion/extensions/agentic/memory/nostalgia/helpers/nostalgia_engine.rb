# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Nostalgia
          module Helpers
            class NostalgiaEngine
              attr_reader :memories, :events

              def initialize
                @memories = []
                @events   = []
              end

              def create_memory(content:, domain: :unknown, warmth: Constants::DEFAULT_WARMTH,
                                original_valence: 0.5)
                memory = NostalgicMemory.new(
                  content:          content,
                  domain:           domain,
                  warmth:           warmth,
                  original_valence: original_valence
                )
                @memories << memory
                @memories.shift while @memories.size > Constants::MAX_MEMORIES
                memory
              end

              def trigger_nostalgia(trigger:, domain: nil, intensity_hint: nil)
                candidates = find_candidates(domain, trigger)
                return [] if candidates.empty?

                new_events = candidates.filter_map do |memory|
                  intensity = compute_intensity(memory, intensity_hint)
                  next unless intensity >= Constants::TRIGGER_SENSITIVITY

                  event = NostalgiaEvent.new(
                    memory_id:      memory.id,
                    trigger:        trigger,
                    intensity:      intensity,
                    effect_on_mood: compute_mood_effect(memory, intensity)
                  )
                  memory.warm!(intensity * 0.1)
                  @events << event
                  event
                end

                @events.shift while @events.size > Constants::MAX_EVENTS
                new_events
              end

              def age_all!
                @memories.each(&:age!)
              end

              def warmth_by_domain
                grouped = @memories.group_by(&:domain)
                grouped.transform_values do |mems|
                  total = mems.sum(&:warmth)
                  (total / mems.size).round(10)
                end
              end

              def rosy_retrospection_index
                return 0.0 if @memories.empty?

                rosy_count = @memories.count(&:rosy?)
                inflation_sum = @memories.select(&:rosy?).sum do |m|
                  m.warmth - m.original_valence
                end

                base = rosy_count.to_f / @memories.size
                avg_inflation = rosy_count.positive? ? inflation_sum / rosy_count : 0.0
                (base * avg_inflation).clamp(0.0, 1.0).round(10)
              end

              def nostalgia_proneness
                return 0.0 if @memories.empty?

                avg_warmth = @memories.sum(&:warmth) / @memories.size
                event_density = [@events.size.to_f / Constants::MAX_EVENTS, 1.0].min
                ((avg_warmth * 0.7) + (event_density * 0.3)).clamp(0.0, 1.0).round(10)
              end

              def most_nostalgic_domains
                warmth_by_domain.sort_by { |_, v| -v }.map do |domain, avg_warmth|
                  { domain: domain, avg_warmth: avg_warmth.round(10) }
                end
              end

              def bittersweet_memories
                @memories.select(&:bittersweet?).map(&:to_h)
              end

              def nostalgia_report
                index = rosy_retrospection_index
                proneness = nostalgia_proneness
                {
                  total_memories:           @memories.size,
                  total_events:             @events.size,
                  rosy_retrospection_index: index,
                  retrospection_label:      Constants.label_for(Constants::RETROSPECTION_LABELS, index),
                  nostalgia_proneness:      proneness,
                  nostalgia_label:          Constants.label_for(Constants::NOSTALGIA_LABELS, proneness),
                  most_nostalgic_domains:   most_nostalgic_domains,
                  bittersweet_count:        bittersweet_memories.size,
                  rosy_count:               @memories.count(&:rosy?)
                }
              end

              private

              def find_candidates(domain, trigger)
                candidates = domain ? @memories.select { |m| m.domain == domain.to_sym } : @memories
                return candidates.last(10) if trigger.nil?

                by_content = candidates.select { |m| content_matches?(m.content, trigger) }
                by_content.empty? ? candidates.last(5) : by_content
              end

              def content_matches?(content, trigger)
                content.to_s.downcase.include?(trigger.to_s.downcase)
              end

              def compute_intensity(memory, hint)
                base = memory.warmth * 0.6
                temporal_boost = [memory.temporal_distance / 1000.0, 0.3].min
                hint_value = hint ? hint.clamp(0.0, 1.0) * 0.2 : 0.0
                (base + temporal_boost + hint_value).clamp(0.0, 1.0).round(10)
              end

              def compute_mood_effect(memory, intensity)
                if memory.bittersweet?
                  (intensity * 0.3).round(10)
                elsif memory.rosy?
                  (intensity * 0.6).round(10)
                else
                  (intensity * 0.4).round(10)
                end
              end
            end
          end
        end
      end
    end
  end
end
