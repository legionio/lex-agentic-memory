# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Memory
        module ImmuneMemory
          module Helpers
            class Encounter
              include Constants

              attr_reader :id, :threat_type, :threat_signature, :severity,
                          :response_type, :response_speed, :outcome, :created_at

              def initialize(threat_type:, threat_signature:, severity: 0.5, response_type: :primary,
                             response_speed: PRIMARY_RESPONSE_SPEED, outcome: :neutralized)
                @id = SecureRandom.uuid
                @threat_type = threat_type.to_sym
                @threat_signature = threat_signature.to_s
                @severity = severity.to_f.clamp(0.0, 1.0)
                @response_type = response_type.to_sym
                @response_speed = response_speed.to_f.round(10)
                @outcome = outcome.to_sym
                @created_at = Time.now
              end

              def secondary? = @response_type == :secondary
              def primary? = @response_type == :primary
              def neutralized? = @outcome == :neutralized
              def evaded? = @outcome == :evaded
              def critical? = @severity >= 0.8

              def to_h
                {
                  id:               @id,
                  threat_type:      @threat_type,
                  threat_signature: @threat_signature,
                  severity:         @severity,
                  response_type:    @response_type,
                  response_speed:   @response_speed,
                  outcome:          @outcome,
                  critical:         critical?,
                  created_at:       @created_at.iso8601
                }
              end
            end
          end
        end
      end
    end
  end
end
