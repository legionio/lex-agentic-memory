# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Paleontology
          module Helpers
            class Excavation
              attr_reader :id, :target_stratum, :fossils_found,
                          :started_at, :completed_at, :status

              def initialize(target_stratum:)
                @id             = SecureRandom.uuid
                @target_stratum = target_stratum.to_i.clamp(0, 4)
                @fossils_found  = []
                @started_at     = Time.now.utc
                @completed_at   = nil
                @status         = :in_progress
              end

              def record_find!(fossil)
                @fossils_found << fossil
              end

              def complete!
                return false if @status == :completed

                @completed_at = Time.now.utc
                @status       = :completed
                true
              end

              def completed?
                @status == :completed
              end

              def yield_rate
                return 0.0 if @fossils_found.empty?

                @fossils_found.sum(&:significance) / @fossils_found.size
              end

              def to_h
                {
                  id:             @id,
                  target_stratum: @target_stratum,
                  stratum_label:  Constants::STRATUM_LABELS[@target_stratum],
                  fossils_count:  @fossils_found.size,
                  yield_rate:     yield_rate.round(10),
                  status:         @status,
                  started_at:     @started_at,
                  completed_at:   @completed_at
                }
              end
            end
          end
        end
      end
    end
  end
end
