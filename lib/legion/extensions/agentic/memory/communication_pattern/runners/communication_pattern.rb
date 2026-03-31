# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module CommunicationPattern
          module Runners
            module CommunicationPattern
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def update_patterns(agent_id:, traces: [], **)
                analyzer = analyzer_for(agent_id)
                analyzer.update_from_traces(traces)

                { success: true, trace_count: analyzer.trace_count,
                  channel_preference: analyzer.channel_preference,
                  direct_address_frequency: analyzer.direct_address_frequency,
                  consistency: analyzer.consistency }
              rescue StandardError => e
                { success: false, error: e.message }
              end

              def analyze_patterns(agent_id:, **)
                analyzer = analyzer_for(agent_id)
                { time_of_day_distribution: analyzer.time_of_day_distribution,
                  day_of_week_distribution: analyzer.day_of_week_distribution,
                  channel_preference:       analyzer.channel_preference,
                  direct_address_frequency: analyzer.direct_address_frequency,
                  topic_clustering:         analyzer.topic_clustering,
                  consistency:              analyzer.consistency,
                  trace_count:              analyzer.trace_count }
              end

              def pattern_stats(agent_id:, **)
                analyzer = analyzer_for(agent_id)
                { trace_count:        analyzer.trace_count,
                  channel_preference: analyzer.channel_preference,
                  consistency:        analyzer.consistency }
              end

              private

              def analyzer_for(agent_id)
                @analyzers ||= {}
                @analyzers[agent_id.to_s] ||= Helpers::PatternAnalyzer.new(agent_id: agent_id.to_s)
              end
            end
          end
        end
      end
    end
  end
end
