# frozen_string_literal: true

require 'securerandom'
require 'time'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Hologram
          module Helpers
            class Hologram
              include Constants

              attr_reader :id, :domain, :content, :fragments, :created_at

              def initialize(domain:, content:)
                @id         = SecureRandom.uuid
                @domain     = domain.to_sym
                @content    = content
                @fragments  = []
                @created_at = Time.now.utc
              end

              def resolution
                return 0.0 if @fragments.empty?

                sufficient = @fragments.select(&:sufficient?)
                return 0.0 if sufficient.empty?

                avg_completeness = sufficient.sum(&:completeness).round(10) / sufficient.size
                avg_fidelity     = sufficient.sum(&:fidelity).round(10) / sufficient.size
                ((avg_completeness + avg_fidelity) / 2.0).round(10)
              end

              def fragment!(count)
                count = count.clamp(1, 20)
                new_fragments = (1..count).map do |i|
                  completeness = ((1.0 / count) + (rand * 0.2)).clamp(0.0, 1.0)
                  fidelity     = (1.0 - ((i - 1).to_f / (count * 2))).clamp(0.0, 1.0)
                  HolographicFragment.new(
                    content:            @content,
                    parent_hologram_id: @id,
                    completeness:       completeness,
                    fidelity:           fidelity
                  )
                end
                @fragments.concat(new_fragments)
                new_fragments
              end

              def reconstruct(fragments)
                sufficient = Array(fragments).select(&:sufficient?)
                return { success: false, reason: :insufficient_fragments, resolution: 0.0 } if sufficient.empty?

                avg_completeness = sufficient.sum(&:completeness).round(10) / sufficient.size
                avg_fidelity     = sufficient.sum(&:fidelity).round(10) / sufficient.size
                reconstructed_resolution = ((avg_completeness + avg_fidelity) / 2.0).round(10)

                {
                  success:         true,
                  resolution:      reconstructed_resolution,
                  label:           resolution_label(reconstructed_resolution),
                  fragment_count:  sufficient.size,
                  total_fragments: fragments.size
                }
              end

              def add_fragment(fragment)
                @fragments << fragment
                fragment
              end

              def resolution_label(res = nil)
                value = res || resolution
                Constants.label_for(Constants::RESOLUTION_LABELS, value)
              end

              def interference_with(other_hologram)
                return 0.0 if other_hologram.nil? || other_hologram.id == @id

                self_words  = tokenize(@content)
                other_words = tokenize(other_hologram.content)

                return 0.0 if self_words.empty? || other_words.empty?

                shared = (self_words & other_words).size
                total  = (self_words | other_words).size
                return 0.0 if total.zero?

                (shared.to_f / total).round(10)
              end

              def to_h
                {
                  id:               @id,
                  domain:           @domain,
                  content:          @content,
                  resolution:       resolution,
                  resolution_label: resolution_label,
                  fragment_count:   @fragments.size,
                  fragments:        @fragments.map(&:to_h),
                  created_at:       @created_at.iso8601
                }
              end

              private

              def tokenize(text)
                text.to_s.downcase.scan(/\w+/).uniq
              end
            end
          end
        end
      end
    end
  end
end
