# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module CommunicationPattern
          module Helpers
            class PatternAnalyzer
              attr_reader :agent_id, :trace_count

              def initialize(agent_id:)
                @agent_id      = agent_id
                @tod_histogram = Array.new(Constants::HOURS_IN_DAY, 0)
                @dow_histogram = Array.new(Constants::DAYS_IN_WEEK, 0)
                @channel_counts    = Hash.new(0)
                @direct_count      = 0
                @topic_counts      = Hash.new(0)
                @trace_count       = 0
                @dirty             = false
              end

              def update_from_traces(traces)
                traces.each { |t| process_trace(t) }
                @dirty = true
              end

              def time_of_day_distribution
                @tod_histogram.dup
              end

              def day_of_week_distribution
                @dow_histogram.dup
              end

              def channel_preference
                @channel_counts.sort_by { |_k, v| -v }.map(&:first)
              end

              def direct_address_frequency
                return 0.0 if @trace_count.zero?

                @direct_count.to_f / @trace_count
              end

              def topic_clustering
                @topic_counts.dup
              end

              def consistency
                return 0.0 if @trace_count < Constants::MIN_TRACES_FOR_PATTERN

                channel_entropy = normalized_entropy(@channel_counts.values)
                tod_entropy     = normalized_entropy(@tod_histogram)
                (1.0 - ((channel_entropy + tod_entropy) / 2.0)).clamp(0.0, 1.0)
              end

              def dirty?
                @dirty
              end

              def mark_clean!
                @dirty = false
                self
              end

              def to_apollo_entries
                tags = Constants::TAG_PREFIX.dup + [@agent_id]
                [{ content: serialize(state_hash), tags: tags }]
              end

              def from_apollo(store:)
                result = store.query(text: 'communication_pattern',
                                     tags: Constants::TAG_PREFIX + [@agent_id])
                return false unless result[:success] && result[:results]&.any?

                parsed = deserialize(result[:results].first[:content])
                return false unless parsed

                restore_state(parsed)
                true
              rescue StandardError => e
                warn "[pattern_analyzer] from_apollo error: #{e.message}"
                false
              end

              private

              def process_trace(trace)
                ts = trace[:created_at]
                ts = Time.parse(ts.to_s) unless ts.is_a?(Time)

                @tod_histogram[ts.hour] += 1
                @dow_histogram[ts.wday] += 1

                payload = trace[:content_payload] || {}
                payload = payload.transform_keys(&:to_sym) if payload.is_a?(Hash)

                channel = payload[:channel]&.to_s
                @channel_counts[channel] += 1 if channel

                @direct_count += 1 if payload[:direct_address]

                (trace[:domain_tags] || []).each { |tag| @topic_counts[tag.to_s] += 1 }

                @trace_count += 1
              rescue StandardError => e
                Legion::Logging.warn("[pattern_analyzer] process_trace error: #{e.message}")
                nil
              end

              def normalized_entropy(counts)
                total = counts.sum.to_f
                return 0.0 if total.zero?

                probs = counts.select(&:positive?).map { |c| c / total }
                max_entropy = Math.log(probs.size)
                return 0.0 if max_entropy.zero?

                entropy = -probs.sum { |p| p * Math.log(p) }
                entropy / max_entropy
              end

              def state_hash
                { agent_id: @agent_id, trace_count: @trace_count,
                  tod_histogram: @tod_histogram, dow_histogram: @dow_histogram,
                  channel_counts: @channel_counts, direct_count: @direct_count,
                  topic_counts: @topic_counts, consistency: consistency }
              end

              def restore_state(parsed)
                @trace_count    = parsed[:trace_count].to_i
                @tod_histogram  = parsed[:tod_histogram] || Array.new(24, 0)
                @dow_histogram  = parsed[:dow_histogram] || Array.new(7, 0)
                @channel_counts = Hash.new(0).merge(parsed[:channel_counts] || {})
                @direct_count   = parsed[:direct_count].to_i
                @topic_counts   = Hash.new(0).merge(parsed[:topic_counts] || {})
              end

              def serialize(hash)
                defined?(Legion::JSON) ? Legion::JSON.dump(hash) : ::JSON.dump(hash)
              end

              def deserialize(content)
                parsed = defined?(Legion::JSON) ? Legion::JSON.parse(content) : ::JSON.parse(content, symbolize_names: true)
                parsed.is_a?(Hash) ? parsed.transform_keys(&:to_sym) : nil
              rescue StandardError => e
                Legion::Logging.warn("[pattern_analyzer] deserialize error: #{e.message}")
                nil
              end
            end
          end
        end
      end
    end
  end
end
