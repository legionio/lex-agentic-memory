# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Episodic
          module Helpers
            class EpisodicStore
              include Constants

              attr_reader :episodes, :history

              def initialize
                @episodes = {}
                @history  = []
              end

              def create_episode
                evict_if_full
                episode = Episode.new
                @episodes[episode.id] = episode
                record_history(:create, episode.id)
                episode
              end

              def add_to_episode(episode_id:, modality:, content:, source:, strength: DEFAULT_BINDING_STRENGTH)
                episode = @episodes[episode_id]
                return { success: false, reason: :episode_not_found } unless episode

                result = episode.add_binding(modality: modality, content: content, source: source, strength: strength)
                record_history(:add_binding, episode_id) if result[:added]
                result
              end

              def attend_episode(episode_id:)
                episode = @episodes[episode_id]
                return { success: false, reason: :episode_not_found } unless episode

                episode.attend
                record_history(:attend, episode_id)
                { success: true, episode_id: episode_id }
              end

              def rehearse_episode(episode_id:)
                episode = @episodes[episode_id]
                return { success: false, reason: :episode_not_found } unless episode

                episode.rehearse
                record_history(:rehearse, episode_id)
                { success: true, episode_id: episode_id }
              end

              def integrate(episode_id:)
                episode = @episodes[episode_id]
                return { integrated: false, reason: :episode_not_found } unless episode

                coherence = episode.coherence
                integrated = coherence >= INTEGRATION_THRESHOLD
                {
                  integrated:      integrated,
                  episode_id:      episode_id,
                  coherence:       coherence,
                  coherence_label: episode.coherence_label
                }
              end

              def retrieve_by_modality(modality:)
                mod = modality.to_sym
                @episodes.values.select { |ep| ep.modalities_present.include?(mod) }
              end

              def retrieve_multimodal
                @episodes.values.select(&:multimodal?)
              end

              def most_coherent(limit: 5)
                @episodes.values
                         .sort_by { |ep| -ep.coherence }
                         .first(limit)
              end

              def tick
                expired_count = 0
                @episodes.delete_if do |_, ep|
                  ep.decay_bindings
                  if ep.expired?
                    expired_count += 1
                    true
                  else
                    false
                  end
                end
                { decayed: @episodes.size, expired: expired_count }
              end

              def count
                @episodes.size
              end

              def to_h
                {
                  episode_count:    @episodes.size,
                  history_size:     @history.size,
                  multimodal_count: retrieve_multimodal.size,
                  avg_coherence:    average_coherence
                }
              end

              private

              def evict_if_full
                return unless @episodes.size >= MAX_EPISODES

                expired = @episodes.values.select(&:expired?)
                if expired.any?
                  oldest = expired.min_by(&:created_at)
                  @episodes.delete(oldest.id)
                else
                  lowest = @episodes.values.min_by(&:coherence)
                  @episodes.delete(lowest.id) if lowest
                end
              end

              def record_history(event, episode_id)
                @history << { event: event, episode_id: episode_id, at: Time.now }
                @history.shift if @history.size > MAX_HISTORY
              end

              def average_coherence
                return 0.0 if @episodes.empty?

                @episodes.values.sum(&:coherence) / @episodes.size
              end
            end
          end
        end
      end
    end
  end
end
