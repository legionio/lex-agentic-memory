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

                  @recent = {}
                  @runner = Object.new.extend(Legion::Extensions::Agentic::Memory::Trace::Runners::Traces)
                  wrap_logging_methods
                  @active = true
                  Legion::Logging.info '[memory] ErrorTracer active — errors/fatals will become episodic traces'
                end

                def active?
                  @active == true
                end

                private

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

                  # Debounce: skip if same message within window
                  now = Time.now.utc
                  key = "#{level}:#{message[0..100]}"
                  return if @recent[key] && (now - @recent[key]) < DEBOUNCE_WINDOW

                  @recent[key] = now

                  # Clean old entries periodically
                  @recent.delete_if { |_, t| (now - t) > DEBOUNCE_WINDOW } if @recent.size > 500

                  # Extract component from [bracket] prefix
                  component = message.match(/\A\[([^\]]+)\]/)&.captures&.first || 'unknown'

                  valence   = level == :fatal ? FATAL_VALENCE : ERROR_VALENCE
                  intensity = level == :fatal ? FATAL_INTENSITY : ERROR_INTENSITY

                  @runner.store_trace(
                    type:                :episodic,
                    content_payload:     message,
                    domain_tags:         ['error', component.downcase],
                    origin:              :direct_experience,
                    emotional_valence:   valence,
                    emotional_intensity: intensity,
                    unresolved:          true,
                    confidence:          0.9
                  )

                  # Flush if cache-backed
                  store = @runner.send(:default_store)
                  store.flush if store.respond_to?(:flush)
                rescue StandardError => _e
                  # Never let trace creation break the logging pipeline
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
