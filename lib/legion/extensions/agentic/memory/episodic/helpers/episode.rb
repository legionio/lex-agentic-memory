# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Episodic
          module Helpers
            class Episode
              include Constants

              attr_reader :id, :bindings, :created_at, :last_accessed

              def initialize
                @id            = SecureRandom.uuid
                @bindings      = {}
                @created_at    = Time.now
                @last_accessed = Time.now
              end

              def add_binding(modality:, content:, source:, strength: DEFAULT_BINDING_STRENGTH)
                return { added: false, reason: :capacity_full } if @bindings.size >= MAX_BINDINGS_PER_EPISODE

                binding = EpisodicBinding.new(modality: modality, content: content, source: source, strength: strength)
                @bindings[binding.id] = binding
                { added: true, binding_id: binding.id }
              end

              def remove_binding(binding_id:)
                removed = !@bindings.delete(binding_id).nil?
                { removed: removed, binding_id: binding_id }
              end

              def attend
                @last_accessed = Time.now
                @bindings.each_value { |b| b.strengthen(ATTENTION_BOOST) }
              end

              def rehearse
                @last_accessed = Time.now
                @bindings.each_value { |b| b.strengthen(REHEARSAL_BOOST) }
              end

              def modalities_present
                @bindings.values.map(&:modality).uniq
              end

              def coherence
                integrated = @bindings.values.select(&:integrated?)
                return 0.0 if integrated.empty?

                integrated.sum(&:strength) / integrated.size
              end

              def coherence_label
                score = coherence
                COHERENCE_LABELS.each do |range, label|
                  return label if range.cover?(score)
                end
                :fragmented
              end

              def multimodal?
                modalities_present.size >= 2
              end

              def expired?
                age = Time.now - @created_at
                age > EPISODE_TTL && !recently_accessed?
              end

              def decay_bindings
                @bindings.each_value(&:decay)
                @bindings.delete_if { |_, b| b.faded? }
              end

              def to_h
                {
                  id:              @id,
                  bindings:        @bindings.transform_values(&:to_h),
                  created_at:      @created_at,
                  last_accessed:   @last_accessed,
                  modalities:      modalities_present,
                  coherence:       coherence,
                  coherence_label: coherence_label,
                  multimodal:      multimodal?,
                  binding_count:   @bindings.size
                }
              end

              private

              def recently_accessed?
                (Time.now - @last_accessed) <= RECENTLY_ACCESSED_WINDOW
              end
            end
          end
        end
      end
    end
  end
end
