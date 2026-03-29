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

                  unless verify_data(packed, signature, agent_id)
                    Legion::Logging.warn "[snapshot] signature verification failed for #{agent_id}" if defined?(Legion::Logging)
                    return { success: false, reason: :invalid_signature }
                  end

                  state = MessagePack.unpack(packed, symbolize_keys: true)
                  distribute_state(state)
                  { success: true, agent_id: agent_id, timestamp: state[:timestamp] }
                rescue StandardError => e
                  Legion::Logging.warn "[snapshot] restore failed: #{e.message}" if defined?(Legion::Logging)
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

                  state[:personality_state] = begin
                    Legion::Extensions::Agentic::Self.personality_snapshot
                  rescue NameError, NoMethodError
                    {}
                  end

                  state[:mood_state] = begin
                    Legion::Extensions::Agentic::Affect.mood_snapshot
                  rescue NameError, NoMethodError
                    {}
                  end

                  state[:trust_scores] = begin
                    Legion::Mesh.trust_snapshot
                  rescue NameError, NoMethodError
                    {}
                  end

                  state[:reflection_history] = begin
                    Legion::Extensions::Agentic::Self.reflection_snapshot
                  rescue NameError, NoMethodError
                    []
                  end

                  state
                end

                def distribute_state(state)
                  if state[:memory_traces]
                    store = Legion::Extensions::Agentic::Memory::Trace.shared_store
                    if store.respond_to?(:restore_traces)
                      store.restore_traces(state[:memory_traces])
                    elsif store.respond_to?(:store)
                      state[:memory_traces].each { |t| store.store(t) }
                    end
                  end

                  if state[:personality_state] && !state[:personality_state].empty?
                    begin
                      Legion::Extensions::Agentic::Self.restore_personality(state[:personality_state])
                    rescue NameError, NoMethodError
                      nil
                    end
                  end

                  if state[:mood_state] && !state[:mood_state].empty?
                    begin
                      Legion::Extensions::Agentic::Affect.restore_mood(state[:mood_state])
                    rescue NameError, NoMethodError
                      nil
                    end
                  end

                  if state[:trust_scores] && !state[:trust_scores].empty?
                    begin
                      Legion::Mesh.restore_trust(state[:trust_scores])
                    rescue NameError, NoMethodError
                      nil
                    end
                  end

                  return unless state[:reflection_history] && !state[:reflection_history].empty?

                  begin
                    Legion::Extensions::Agentic::Self.restore_reflections(state[:reflection_history])
                  rescue NameError, NoMethodError
                    nil
                  end
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
