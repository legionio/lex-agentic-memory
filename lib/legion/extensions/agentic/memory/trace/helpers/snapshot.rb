# frozen_string_literal: true

require 'msgpack'
require 'fileutils'
require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Trace
          module Helpers
            module Snapshot
              class << self
                include Legion::Logging::Helper if defined?(Legion::Logging::Helper)

                def save_snapshot(agent_id:)
                  state = gather_state(agent_id)
                  packed = MessagePack.pack(state)
                  signed = sign_data(packed, agent_id)

                  dir = snapshot_dir(agent_id)
                  FileUtils.mkdir_p(dir)
                  filename = "#{Time.now.utc.strftime('%Y%m%d%H%M%S%L')}_#{SecureRandom.hex(4)}.snapshot"
                  path = File.join(dir, filename)
                  File.binwrite(path, signed)

                  prune_snapshots(agent_id: agent_id)
                  { success: true, path: path, size: signed.bytesize }
                end

                def restore_snapshot(agent_id:)
                  path = latest_snapshot_path(agent_id)
                  return { success: false, reason: :no_snapshot } unless path

                  raw = File.binread(path)
                  return { success: false, reason: :too_small } if raw.bytesize < 65

                  signature = raw[-64..]
                  packed = raw[0..-65]

                  return { success: false, reason: :invalid_signature } unless verify_data(packed, signature, agent_id)

                  state = MessagePack.unpack(packed, symbolize_keys: true)
                  distribute_state(state)
                  { success: true, agent_id: agent_id, timestamp: state[:timestamp] }
                rescue StandardError => e
                  log.error(e.message)
                  { success: false, reason: :error, message: e.message }
                end

                def list_snapshots(agent_id:)
                  dir = snapshot_dir(agent_id)
                  return { success: true, snapshots: [] } unless Dir.exist?(dir)

                  files = Dir.glob(File.join(dir, '*.snapshot')).map do |f|
                    { filename: File.basename(f), size: File.size(f), mtime: File.mtime(f) }
                  end
                  { success: true, snapshots: files }
                end

                def prune_snapshots(agent_id:, max_count: 10)
                  dir = snapshot_dir(agent_id)
                  return { success: true, pruned: 0 } unless Dir.exist?(dir)

                  files = Dir.glob(File.join(dir, '*.snapshot'))
                  excess = files.size - max_count
                  return { success: true, pruned: 0 } if excess <= 0

                  files.first(excess).each { |f| File.delete(f) }
                  { success: true, pruned: excess }
                end

                private

                def snapshot_dir(agent_id)
                  base = Legion::Settings.dig(:snapshot, :directory) if defined?(Legion::Settings)
                  File.join(base || File.expand_path('~/.legionio/snapshots'), agent_id.to_s)
                end

                def latest_snapshot_path(agent_id)
                  dir = snapshot_dir(agent_id)
                  return nil unless Dir.exist?(dir)

                  Dir.glob(File.join(dir, '*.snapshot')).max
                end

                def gather_state(agent_id)
                  state = { agent_id: agent_id, schema_version: 1, timestamp: Time.now.utc.iso8601 }

                  store = Legion::Extensions::Agentic::Memory::Trace.shared_store
                  state[:memory_traces] = if store.respond_to?(:all_traces)
                                            traces = store.all_traces
                                            traces.is_a?(Array) ? traces : traces.values
                                          else
                                            []
                                          end

                  state[:personality_state] =
                    if defined?(Legion::Extensions::Agentic::Self) &&
                       Legion::Extensions::Agentic::Self.respond_to?(:personality_snapshot)
                      Legion::Extensions::Agentic::Self.personality_snapshot
                    else
                      {}
                    end

                  state[:mood_state] =
                    if defined?(Legion::Extensions::Agentic::Affect) &&
                       Legion::Extensions::Agentic::Affect.respond_to?(:mood_snapshot)
                      Legion::Extensions::Agentic::Affect.mood_snapshot
                    else
                      {}
                    end

                  state[:trust_scores] =
                    if defined?(Legion::Mesh) && Legion::Mesh.respond_to?(:trust_snapshot)
                      Legion::Mesh.trust_snapshot
                    else
                      {}
                    end

                  state[:reflection_history] =
                    if defined?(Legion::Extensions::Agentic::Self) &&
                       Legion::Extensions::Agentic::Self.respond_to?(:reflection_snapshot)
                      Legion::Extensions::Agentic::Self.reflection_snapshot
                    else
                      []
                    end

                  state
                end

                def distribute_state(state)
                  restore_memory_traces(state[:memory_traces])
                  restore_personality(state[:personality_state])
                  restore_mood(state[:mood_state])
                  restore_trust_scores(state[:trust_scores])
                  restore_reflections(state[:reflection_history])
                end

                def restore_memory_traces(traces)
                  return unless traces

                  store = Legion::Extensions::Agentic::Memory::Trace.shared_store
                  if store.respond_to?(:restore_traces)
                    store.restore_traces(traces)
                  elsif store.respond_to?(:store)
                    traces.each { |t| store.store(t) }
                  end
                end

                def restore_personality(personality_state)
                  return unless personality_state && !personality_state.empty?
                  return unless defined?(Legion::Extensions::Agentic::Self) &&
                                Legion::Extensions::Agentic::Self.respond_to?(:restore_personality)

                  Legion::Extensions::Agentic::Self.restore_personality(personality_state)
                end

                def restore_mood(mood_state)
                  return unless mood_state && !mood_state.empty?
                  return unless defined?(Legion::Extensions::Agentic::Affect) &&
                                Legion::Extensions::Agentic::Affect.respond_to?(:restore_mood)

                  Legion::Extensions::Agentic::Affect.restore_mood(mood_state)
                end

                def restore_trust_scores(trust_scores)
                  return unless trust_scores && !trust_scores.empty?
                  return unless defined?(Legion::Mesh) && Legion::Mesh.respond_to?(:restore_trust)

                  Legion::Mesh.restore_trust(trust_scores)
                end

                def restore_reflections(reflection_history)
                  return unless reflection_history && !reflection_history.empty?
                  return unless defined?(Legion::Extensions::Agentic::Self) &&
                                Legion::Extensions::Agentic::Self.respond_to?(:restore_reflections)

                  Legion::Extensions::Agentic::Self.restore_reflections(reflection_history)
                end

                def sign_data(data, _agent_id)
                  if defined?(Legion::Crypt) && Legion::Crypt.respond_to?(:ed25519_sign)
                    signature = Legion::Crypt.ed25519_sign(data)
                    data + signature
                  else
                    require 'digest'
                    hash = Digest::SHA512.digest(data)
                    data + hash[0, 64]
                  end
                end

                def verify_data(data, signature, _agent_id)
                  if defined?(Legion::Crypt) && Legion::Crypt.respond_to?(:ed25519_verify)
                    Legion::Crypt.ed25519_verify(data, signature)
                  else
                    require 'digest'
                    expected = Digest::SHA512.digest(data)[0, 64]
                    signature == expected
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
