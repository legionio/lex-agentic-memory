# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Episodic
          module Runners
            module EpisodicBuffer
              def create_episode(**)
                store = default_store
                episode = store.create_episode
                Legion::Logging.debug "[episodic_buffer] created episode id=#{episode.id[0..7]}"
                { success: true, episode_id: episode.id, created_at: episode.created_at }
              end

              def add_binding(episode_id:, modality:, content:, source:,
                              strength: Helpers::Constants::DEFAULT_BINDING_STRENGTH, **)
                raise ArgumentError, "invalid modality: #{modality}" unless Helpers::Constants::MODALITIES.include?(modality.to_sym)

                store  = default_store
                result = store.add_to_episode(
                  episode_id: episode_id,
                  modality:   modality.to_sym,
                  content:    content,
                  source:     source,
                  strength:   strength
                )

                if result[:added]
                  Legion::Logging.debug "[episodic_buffer] add_binding ep=#{episode_id[0..7]} mod=#{modality}"
                  { success: true, episode_id: episode_id, binding_id: result[:binding_id] }
                else
                  Legion::Logging.debug "[episodic_buffer] add_binding failed ep=#{episode_id[0..7]} r=#{result[:reason]}"
                  { success: false, episode_id: episode_id, reason: result[:reason] }
                end
              end

              def attend_episode(episode_id:, **)
                store  = default_store
                result = store.attend_episode(episode_id: episode_id)
                Legion::Logging.debug "[episodic_buffer] attend ep=#{episode_id[0..7]} success=#{result[:success]}"
                result.merge(success: result[:success])
              end

              def rehearse_episode(episode_id:, **)
                store  = default_store
                result = store.rehearse_episode(episode_id: episode_id)
                Legion::Logging.debug "[episodic_buffer] rehearse ep=#{episode_id[0..7]} success=#{result[:success]}"
                result.merge(success: result[:success])
              end

              def check_integration(episode_id:, **)
                store  = default_store
                result = store.integrate(episode_id: episode_id)
                Legion::Logging.debug "[episodic_buffer] check_integration ep=#{episode_id[0..7]} ok=#{result[:integrated]}"
                result.merge(success: true)
              end

              def retrieve_by_modality(modality:, **)
                store    = default_store
                episodes = store.retrieve_by_modality(modality: modality.to_sym)
                Legion::Logging.debug "[episodic_buffer] retrieve_by_modality mod=#{modality} count=#{episodes.size}"
                { success: true, modality: modality, count: episodes.size, episodes: episodes.map(&:to_h) }
              end

              def retrieve_multimodal(**)
                store    = default_store
                episodes = store.retrieve_multimodal
                Legion::Logging.debug "[episodic_buffer] retrieve_multimodal count=#{episodes.size}"
                { success: true, count: episodes.size, episodes: episodes.map(&:to_h) }
              end

              def most_coherent(limit: 5, **)
                store    = default_store
                episodes = store.most_coherent(limit: limit)
                Legion::Logging.debug "[episodic_buffer] most_coherent limit=#{limit} returned=#{episodes.size}"
                { success: true, count: episodes.size, episodes: episodes.map(&:to_h) }
              end

              def update_episodic_buffer(**)
                store  = default_store
                result = store.tick
                Legion::Logging.debug "[episodic_buffer] tick decayed=#{result[:decayed]} expired=#{result[:expired]}"
                { success: true }.merge(result)
              end

              def episodic_buffer_stats(**)
                store = default_store
                stats = store.to_h
                Legion::Logging.debug "[episodic_buffer] stats episodes=#{stats[:episode_count]}"
                { success: true }.merge(stats)
              end

              private

              def default_store
                @default_store ||= Helpers::EpisodicStore.new
              end

              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)
            end
          end
        end
      end
    end
  end
end
