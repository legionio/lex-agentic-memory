# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Trace
          module Helpers
            module ErrorTracer
              DEBOUNCE_WINDOW = 60 # seconds
              ERROR_VALENCE   = -0.6
              ERROR_INTENSITY = 0.7
              FATAL_VALENCE   = -0.8
              FATAL_INTENSITY = 0.9

              class << self
                def setup
                  return if @active

                  @recent       = {}
                  @recent_mutex = ::Mutex.new
                  @runner       = Object.new.extend(Legion::Extensions::Agentic::Memory::Trace::Runners::Traces)
                  @write_queue  = ::Queue.new
                  @worker       = ::Thread.new { drain_queue }
                  @worker.name  = 'legion-error-tracer'
                  wrap_logging_methods
                  @active = true
                  Legion::Logging.info '[memory] ErrorTracer active — errors/fatals will become episodic traces'
                end

                def active?
                  @active == true
                end

                private

                def drain_queue
                  loop do
                    payload = @write_queue.pop
                    break if payload == :stop

                    @runner.store_trace(**payload)
                    store = @runner.send(:default_store)
                    store.flush if store.respond_to?(:flush)
                  rescue StandardError
                    nil
                  end
                end

                def wrap_logging_methods
                  original_error = Legion::Logging.method(:error)
                  original_fatal = Legion::Logging.method(:fatal)

                  Legion::Logging.define_singleton_method(:error) do |message = nil, &block|
                    message = block.call if message.nil? && block
                    original_error.call(message)
                    ErrorTracer.send(:record_trace, message, :error) if message.is_a?(String)
                  end

                  Legion::Logging.define_singleton_method(:fatal) do |message = nil, &block|
                    message = block.call if message.nil? && block
                    original_fatal.call(message)
                    ErrorTracer.send(:record_trace, message, :fatal) if message.is_a?(String)
                  end
                end

                def record_trace(message, level)
                  return unless message.is_a?(String) && !message.empty?

                  now = Time.now.utc
                  key = "#{level}:#{message[0..100]}"

                  @recent_mutex.synchronize do
                    return if @recent[key] && (now - @recent[key]) < DEBOUNCE_WINDOW

                    @recent[key] = now
                    @recent.delete_if { |_, t| (now - t) > DEBOUNCE_WINDOW } if @recent.size > 500
                  end

                  component = message.match(/\A\[([^\]]+)\]/)&.captures&.first || 'unknown'
                  valence   = level == :fatal ? FATAL_VALENCE : ERROR_VALENCE
                  intensity = level == :fatal ? FATAL_INTENSITY : ERROR_INTENSITY

                  @write_queue.push(
                    type:                :episodic,
                    content_payload:     message,
                    domain_tags:         ['error', component.downcase],
                    origin:              :direct_experience,
                    emotional_valence:   valence,
                    emotional_intensity: intensity,
                    unresolved:          true,
                    confidence:          0.9
                  )
                rescue StandardError
                  nil
                end
              end
            end
          end
        end
      end
    end
  end
end
