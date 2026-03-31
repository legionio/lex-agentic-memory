# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module CommunicationPattern
          module Helpers
            module Constants
              HOURS_IN_DAY = 24
              DAYS_IN_WEEK = 7

              MESSAGE_LENGTH_BUCKETS = %i[short medium long].freeze
              MESSAGE_LENGTH_THRESHOLDS = { short: 50, medium: 200 }.freeze

              SLIDING_WINDOW_SIZE = 100
              MIN_TRACES_FOR_PATTERN = 10

              TAG_PREFIX = %w[bond communication_pattern].freeze
            end
          end
        end
      end
    end
  end
end
