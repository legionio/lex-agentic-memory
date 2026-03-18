# frozen_string_literal: true

require 'securerandom'
require_relative 'constants'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Offloading
          module Helpers
            class ExternalStore
              include Constants

              attr_reader :id, :name, :store_type, :trust, :items_stored,
                          :successful_retrievals, :failed_retrievals, :created_at

              def initialize(name:, store_type:)
                @id                   = ::SecureRandom.uuid
                @name                 = name
                @store_type           = store_type
                @trust                = DEFAULT_STORE_TRUST
                @items_stored         = 0
                @successful_retrievals = 0
                @failed_retrievals     = 0
                @created_at = Time.now.utc
              end

              def increment_items!
                @items_stored += 1
                self
              end

              def record_success!
                @successful_retrievals += 1
                @trust = (@trust + TRUST_BOOST).clamp(0.0, 1.0).round(10)
                self
              end

              def record_failure!
                @failed_retrievals += 1
                @trust = (@trust - TRUST_DECAY).clamp(0.0, 1.0).round(10)
                self
              end

              def retrieval_rate
                total = @successful_retrievals + @failed_retrievals
                return 0.0 if total.zero?

                (@successful_retrievals.to_f / total).round(10)
              end

              def reliable?
                @trust >= RETRIEVAL_SUCCESS_THRESHOLD
              end

              def trust_label
                TRUST_LABELS.find { |range, _| range.cover?(@trust) }&.last || :unreliable
              end

              def to_h
                {
                  id:                    @id,
                  name:                  @name,
                  store_type:            @store_type,
                  trust:                 @trust.round(10),
                  trust_label:           trust_label,
                  items_stored:          @items_stored,
                  successful_retrievals: @successful_retrievals,
                  failed_retrievals:     @failed_retrievals,
                  retrieval_rate:        retrieval_rate,
                  reliable:              reliable?,
                  created_at:            @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
