# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module SourceMonitoring
          module Helpers
            class SourceRecord
              include Constants

              attr_reader :id, :content_id, :source, :domain, :context, :recorded_at
              attr_accessor :confidence, :verified

              def initialize(id:, content_id:, source:, domain: :general, confidence: DEFAULT_CONFIDENCE, context: {})
                @id          = id
                @content_id  = content_id
                @source      = source
                @domain      = domain
                @confidence  = confidence.to_f.clamp(0.0, 1.0)
                @context     = context
                @verified    = false
                @recorded_at = Time.now.utc
                @corrections = []
              end

              def reality_status
                REALITY_STATUS.fetch(@source, :uncertain)
              end

              def external?
                @source == :external_perception
              end

              def internal?
                %i[internal_generation imagination dream].include?(@source)
              end

              def verify
                @verified = true
                @confidence = [@confidence + 0.15, 1.0].min
              end

              def correct(new_source:)
                @corrections << { from: @source, to: new_source, at: Time.now.utc }
                @source = new_source
                @confidence = [@confidence * 0.8, CONFIDENCE_FLOOR].max
              end

              def correction_count
                @corrections.size
              end

              def confused?
                CONFUSION_PAIRS.any? { |pair| pair.include?(@source) } && @confidence < 0.5
              end

              def decay
                @confidence = [@confidence - CONFIDENCE_DECAY, CONFIDENCE_FLOOR].max
              end

              def faded?
                @confidence <= CONFIDENCE_FLOOR && !@verified
              end

              def confidence_label
                CONFIDENCE_LABELS.each { |range, lbl| return lbl if range.cover?(@confidence) }
                :guessing
              end

              def to_h
                {
                  id:               @id,
                  content_id:       @content_id,
                  source:           @source,
                  domain:           @domain,
                  reality_status:   reality_status,
                  confidence:       @confidence.round(4),
                  confidence_label: confidence_label,
                  verified:         @verified,
                  external:         external?,
                  internal:         internal?,
                  confused:         confused?,
                  corrections:      correction_count,
                  recorded_at:      @recorded_at
                }
              end
            end
          end
        end
      end
    end
  end
end
