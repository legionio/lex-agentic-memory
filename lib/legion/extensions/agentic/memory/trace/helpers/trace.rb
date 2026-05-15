# frozen_string_literal: true

require 'json'
require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Trace
          module Helpers
            module Trace
              TRACE_TYPES = %i[firmware identity procedural trust semantic episodic sensory].freeze

              ORIGINS = %i[firmware direct_experience mesh_transfer imprint].freeze

              STORAGE_TIERS = %i[hot warm cold erased].freeze

              BASE_DECAY_RATES = {
                firmware:   0.000,
                identity:   0.001,
                procedural: 0.005,
                trust:      0.008,
                semantic:   0.010,
                episodic:   0.020,
                sensory:    0.100
              }.freeze

              STARTING_STRENGTHS = {
                firmware:   1.000,
                identity:   1.000,
                procedural: 0.400,
                trust:      0.300,
                semantic:   0.500,
                episodic:   0.600,
                sensory:    0.400
              }.freeze

              # Tuning constants from spec Section 4.5
              E_WEIGHT                = 0.3   # emotional intensity weight on decay
              R_AMOUNT                = 0.10  # base reinforcement amount
              IMPRINT_MULTIPLIER      = 3.0   # reinforcement boost during imprint window
              AUTO_FIRE_THRESHOLD     = 0.85  # procedural auto-fire strength threshold
              ARCHIVE_THRESHOLD       = 0.05  # below this, trace moves to cold storage
              PRUNE_THRESHOLD         = 0.01  # below this, trace eligible for removal
              HOT_TIER_WINDOW         = 86_400    # 24 hours in seconds
              WARM_TIER_WINDOW        = 7_776_000 # 90 days in seconds
              RETRIEVAL_RECENCY_HALF  = 3600      # half-life for recency scoring (1 hour)
              ASSOCIATION_BONUS       = 0.15  # bonus for Hebbian-associated traces
              MAX_ASSOCIATIONS        = 20    # max Hebbian links per trace
              COACTIVATION_THRESHOLD  = 3     # co-activations before Hebbian link forms
              VALENCE_SCALAR_KEYS     = %i[valence emotional_valence sentiment polarity score].freeze

              module_function

              def new_trace(type:, content_payload:, content_embedding: nil, emotional_valence: 0.0, # rubocop:disable Metrics/ParameterLists
                            emotional_intensity: 0.0, domain_tags: [], origin: :direct_experience,
                            source_agent_id: nil, partition_id: nil, imprint_active: false,
                            unresolved: false, consolidation_candidate: false, confidence: nil, **)
                raise ArgumentError, "invalid trace type: #{type}" unless TRACE_TYPES.include?(type)
                raise ArgumentError, "invalid origin: #{origin}" unless ORIGINS.include?(origin)

                now = Time.now.utc
                emotional_context = normalize_trace_affect(
                  emotional_valence:   emotional_valence,
                  emotional_intensity: emotional_intensity
                )

                {
                  trace_id:                SecureRandom.uuid,
                  trace_type:              type,
                  content_embedding:       content_embedding,
                  content_payload:         content_payload,
                  strength:                STARTING_STRENGTHS[type],
                  peak_strength:           STARTING_STRENGTHS[type],
                  base_decay_rate:         BASE_DECAY_RATES[type],
                  emotional_valence:       emotional_context[:emotional_valence],
                  emotional_intensity:     emotional_context[:emotional_intensity],
                  domain_tags:             Array(domain_tags),
                  origin:                  origin,
                  source_agent_id:         source_agent_id,
                  created_at:              now,
                  last_reinforced:         now,
                  last_decayed:            now,
                  reinforcement_count:     imprint_active ? 1 : 0,
                  confidence:              confidence || (type == :firmware ? 1.0 : 0.5),
                  storage_tier:            :hot,
                  partition_id:            partition_id || default_partition_id,
                  encryption_key_id:       nil,
                  associated_traces:       [],
                  parent_trace_id:         nil,
                  child_trace_ids:         [],
                  unresolved:              unresolved,
                  consolidation_candidate: consolidation_candidate
                }
              end

              def valid_trace?(trace)
                return false unless trace.is_a?(Hash)
                return false unless TRACE_TYPES.include?(trace[:trace_type])
                return false unless trace[:strength].is_a?(Numeric)
                return false unless trace[:strength].between?(0.0, 1.0)

                true
              end

              def normalize_trace_affect(trace)
                normalized = trace.dup
                normalized[:emotional_valence] = normalize_emotional_valence(normalized[:emotional_valence])
                normalized[:emotional_intensity] = normalize_emotional_intensity(normalized[:emotional_intensity])
                normalized
              end

              def normalize_emotional_valence(value)
                normalize_scalar(value, min: -1.0, max: 1.0, hash_keys: VALENCE_SCALAR_KEYS)
              end

              def normalize_emotional_intensity(value)
                normalize_scalar(value, min: 0.0, max: 1.0)
              end

              def default_partition_id
                Legion::Settings.dig(:agent, :id) || 'default'
              rescue StandardError => _e
                'default'
              end

              def normalize_scalar(value, min:, max:, hash_keys: [])
                case value
                when Numeric
                  value.to_f.clamp(min, max)
                when String
                  normalize_string_scalar(value, min: min, max: max, hash_keys: hash_keys)
                when Hash
                  normalize_hash_scalar(value, min: min, max: max, hash_keys: hash_keys)
                else
                  0.0
                end
              end

              def normalize_string_scalar(value, min:, max:, hash_keys:)
                stripped = value.strip
                return 0.0 if stripped.empty?

                Float(stripped).clamp(min, max)
              rescue ArgumentError, TypeError => e
                Legion::Logging.debug("[memory][trace] normalize_string_scalar fallback: #{e.message}")
                parsed = parse_structured_scalar(stripped)
                return normalize_scalar(parsed, min: min, max: max, hash_keys: hash_keys) if parsed

                0.0
              end

              def normalize_hash_scalar(value, min:, max:, hash_keys:)
                symbolized = symbolize_keys(value)
                scalar_value = hash_keys.lazy.map { |key| symbolized[key] }.find { |candidate| scalar_candidate?(candidate) }
                return normalize_scalar(scalar_value, min: min, max: max, hash_keys: hash_keys) if scalar_candidate?(scalar_value)

                numeric_values = symbolized.values.select { |candidate| scalar_candidate?(candidate) }
                return normalize_scalar(numeric_values.first, min: min, max: max, hash_keys: hash_keys) if numeric_values.one?

                0.0
              end

              def parse_structured_scalar(value)
                return unless value.start_with?('{', '[')

                ::JSON.parse(value)
              rescue ::JSON::ParserError => e
                Legion::Logging.debug("[memory][trace] parse_structured_scalar ignored: #{e.message}")
                nil
              end

              def scalar_candidate?(value)
                value.is_a?(Numeric) || value.is_a?(String)
              end

              def symbolize_keys(value)
                case value
                when Hash
                  value.each_with_object({}) do |(key, nested), memo|
                    memo[key.to_sym] = symbolize_keys(nested)
                  end
                when Array
                  value.map { |nested| symbolize_keys(nested) }
                else
                  value
                end
              end
            end
          end
        end
      end
    end
  end
end
