# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Memory
        module Consolidation
          module Helpers
            module Extractor
              CATEGORY_PATTERNS = {
                decisions:   /\b(decided|decision|went with|choose|chosen|locked in|settled on)\b/i,
                preferences: /\b(always|never|prefer|preference|use .* by default|do not|don't)\b/i,
                milestones:  /\b(worked|fixed|green|merged|shipped|completed|breakthrough|finally)\b/i,
                problems:    /\b(bug|failed|failing|failure|broken|error|crash|root cause|regression|blocked)\b/i,
                discoveries: /\b(found|learned|discovered|turns out|confirmed|observed)\b/i
              }.freeze

              module_function

              def extract(transcript)
                lines = transcript_lines(transcript)
                CATEGORY_PATTERNS.each_with_object({}) do |(category, pattern), summary|
                  summary[category] = lines.grep(pattern).uniq
                end
              end

              def transcript_lines(transcript)
                text = transcript_text(transcript)
                text.split(/[\r\n]+|(?<=[.!?])\s+/)
                    .map { |line| line.strip.gsub(/\s+/, ' ') }
                    .reject(&:empty?)
              end

              def transcript_text(transcript)
                case transcript
                when String
                  transcript
                when Array
                  transcript.map { |entry| entry_text(entry) }.join("\n")
                else
                  session_messages(transcript).map { |entry| entry_text(entry) }.join("\n")
                end
              end

              def session_messages(session)
                return [] unless session
                return session.transcript if session.respond_to?(:transcript)
                return session.messages if session.respond_to?(:messages)
                return session.chat.messages if session.respond_to?(:chat) && session.chat.respond_to?(:messages)

                []
              end

              def entry_text(entry)
                return entry if entry.is_a?(String)

                if entry.respond_to?(:to_h)
                  hash = entry.to_h
                  return hash[:content] || hash['content'] || hash[:text] || hash['text'] || hash.to_s
                end

                entry.respond_to?(:content) ? entry.content.to_s : entry.to_s
              end
            end
          end
        end
      end
    end
  end
end
