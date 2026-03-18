# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module SourceMonitoring
          module Helpers
            class SourceTracker
              include Constants

              attr_reader :records, :attribution_log

              def initialize
                @records         = {}
                @attribution_log = []
                @record_counter  = 0
                @accuracy_hits   = 0
                @accuracy_total  = 0
              end

              def record_source(content_id:, source:, domain: :general, confidence: DEFAULT_CONFIDENCE, context: {})
                return nil unless SOURCES.include?(source)
                return nil if @records.size >= MAX_RECORDS

                @record_counter += 1
                rec_id = :"src_#{@record_counter}"
                rec = SourceRecord.new(
                  id: rec_id, content_id: content_id, source: source,
                  domain: domain, confidence: confidence, context: context
                )
                @records[rec_id] = rec
                rec
              end

              def attribute(content_id:)
                @records.values.select { |r| r.content_id == content_id }.sort_by { |r| -r.confidence }
              end

              def verify_source(record_id:)
                rec = @records[record_id]
                return nil unless rec

                rec.verify
                @accuracy_hits += 1
                @accuracy_total += 1
                log_attribution(record_id, :verified)
                rec
              end

              def correct_source(record_id:, new_source:)
                rec = @records[record_id]
                return nil unless rec
                return nil unless SOURCES.include?(new_source)

                old = rec.source
                rec.correct(new_source: new_source)
                @accuracy_total += 1
                log_attribution(record_id, :corrected, from: old, to: new_source)
                rec
              end

              def reality_check(content_id:)
                records = attribute(content_id: content_id)
                return { status: :unknown, confidence: 0.0 } if records.empty?

                best = records.first
                { status: best.reality_status, confidence: best.confidence, source: best.source, verified: best.verified }
              end

              def confused_records
                @records.values.select(&:confused?).map(&:to_h)
              end

              def records_by_source(source:)
                @records.values.select { |r| r.source == source }.map(&:to_h)
              end

              def records_in_domain(domain:)
                @records.values.select { |r| r.domain == domain }.map(&:to_h)
              end

              def attribution_accuracy
                return 0.0 if @accuracy_total.zero?

                @accuracy_hits.to_f / @accuracy_total
              end

              def decay_all
                @records.each_value(&:decay)
                @records.reject! { |_, r| r.faded? }
              end

              def to_h
                source_dist = SOURCES.to_h { |s| [s, @records.values.count { |r| r.source == s }] }
                {
                  total_records:        @records.size,
                  verified_count:       @records.values.count(&:verified),
                  confused_count:       @records.values.count(&:confused?),
                  accuracy:             attribution_accuracy.round(4),
                  source_distribution:  source_dist,
                  attribution_log_size: @attribution_log.size
                }
              end

              private

              def log_attribution(record_id, action, **extra)
                entry = { record_id: record_id, action: action, at: Time.now.utc }.merge(extra)
                @attribution_log << entry
                @attribution_log.shift while @attribution_log.size > MAX_ATTRIBUTIONS
              end
            end
          end
        end
      end
    end
  end
end
