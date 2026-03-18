# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module SourceMonitoring
          module Runners
            module SourceMonitoring
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def record_source(content_id:, source:, domain: :general, confidence: nil, context: {}, **)
                conf = confidence || Helpers::Constants::DEFAULT_CONFIDENCE
                Legion::Logging.debug "[source_monitoring] record: content=#{content_id} source=#{source}"
                rec = tracker.record_source(
                  content_id: content_id, source: source.to_sym,
                  domain: domain, confidence: conf, context: context
                )
                if rec
                  { success: true, record: rec.to_h }
                else
                  { success: false, reason: :invalid_or_full }
                end
              end

              def attribute_source(content_id:, **)
                records = tracker.attribute(content_id: content_id)
                Legion::Logging.debug "[source_monitoring] attribute: content=#{content_id} found=#{records.size}"
                { success: true, records: records.map(&:to_h), count: records.size }
              end

              def verify_source(record_id:, **)
                Legion::Logging.debug "[source_monitoring] verify: #{record_id}"
                rec = tracker.verify_source(record_id: record_id.to_sym)
                if rec
                  { success: true, record: rec.to_h }
                else
                  { success: false, reason: :not_found }
                end
              end

              def correct_source(record_id:, new_source:, **)
                Legion::Logging.debug "[source_monitoring] correct: #{record_id} -> #{new_source}"
                rec = tracker.correct_source(record_id: record_id.to_sym, new_source: new_source.to_sym)
                if rec
                  { success: true, record: rec.to_h }
                else
                  { success: false, reason: :not_found_or_invalid }
                end
              end

              def reality_check(content_id:, **)
                result = tracker.reality_check(content_id: content_id)
                Legion::Logging.debug "[source_monitoring] reality_check: #{content_id} => #{result[:status]}"
                { success: true, **result }
              end

              def confused_sources(**)
                confused = tracker.confused_records
                { success: true, confused: confused, count: confused.size }
              end

              def sources_by_type(source:, **)
                records = tracker.records_by_source(source: source.to_sym)
                { success: true, records: records, count: records.size }
              end

              def attribution_accuracy(**)
                { success: true, accuracy: tracker.attribution_accuracy.round(4) }
              end

              def update_source_monitoring(**)
                Legion::Logging.debug '[source_monitoring] tick'
                tracker.decay_all
                { success: true, records: tracker.records.size }
              end

              def source_monitoring_stats(**)
                Legion::Logging.debug '[source_monitoring] stats'
                { success: true, stats: tracker.to_h }
              end

              private

              def tracker
                @tracker ||= Helpers::SourceTracker.new
              end
            end
          end
        end
      end
    end
  end
end
