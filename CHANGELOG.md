# Changelog

## [0.1.32] - 2026-05-07
### Fixed
- Trace association retrieval now snapshots associated traces under the store mutex before filtering.
- Local trace restore preserves symbol keys for JSON fields that are consumed as symbol-keyed hashes.

## [0.1.31] - 2026-04-27
### Added
- Add a heuristic pre-compaction memory save path and synchronous pre-compaction event listeners for `chat.pre_compact`, `context.pre_compact`, and `conversation.pre_compact`.

### Fixed
- Require `legion/logging` and `legion/cache/helper` before `CacheStore` includes helper APIs, preventing `log` or cache helper methods from being skipped when the file is loaded directly.
- Pass `CacheStore` TTL values through `cache_set` as keywords so flushes work with the shared cache helper API.

## [0.1.30] - 2026-04-27
### Fixed
- Local trace persistence now writes only changed trace rows instead of upserting every trace in the partition for a one-trace update.
- Local association persistence now stores `partition_id` and restores associations by partition, avoiding a startup query with one giant trace-id `IN (...)` list.

## [0.1.29] - 2026-04-22
### Fixed
- `parse_db_content` no longer attempts JSON parse on plain-text content — checks for `{`/`[` prefix before parsing, returns raw string for non-JSON content without logging errors

## [0.1.28] - 2026-04-22
### Fixed
- Snapshot save/restore now logs warnings when Self/Affect module methods are unavailable instead of silently skipping
- 26+ silent rescue blocks in trace persistence layer (postgres_store, store, hot_tier) now log errors via `log.error`
### Changed
- CLAUDE.md updated to document all 16 actors (was 5) and CommunicationPattern sub-module

## [0.1.27] - 2026-04-17
### Fixed
- Add missing `Legion::Logging::Helper` include to `CacheStore` — resolves `NameError: undefined local variable or method 'log'` crash on startup when Memcached is available (#23)

## [0.1.26] - 2026-04-15
### Changed
- Set `mcp_tools?`, `mcp_tools_deferred?`, and `transport_required?` to `false` — internal cognitive pipeline extension

## [Unreleased]

### Fixed
- fix retrieve_ranked to return Hash with traces key instead of bare Array for GAIA phase wiring
- add respond_to? guards in Quota#enforce! for store methods not present on all backends
- add lazy default_engine initialization in CognitiveImmuneMemory runner

## [0.1.24] - 2026-04-03

### Fixed
- Wrap `save_to_local` persist in a single SQLite transaction — 32K individual lock acquisitions become 1
- Use `insert_conflict(:replace)` instead of SELECT-then-INSERT/UPDATE per trace

## [0.1.23] - 2026-04-03

### Fixed
- Sanitize trace content before SQLite persist: force-decode to BINARY then re-encode UTF-8, strip null bytes — prevents `unrecognized token` SQL errors from unescaped characters

## [0.1.22] - 2026-04-03

### Changed
- Refactor `Store#save_to_local` into `snapshot_dirty_state`, `persist_dirty_traces`, `persist_dirty_associations`, and `clear_dirty_flags` helpers to reduce cyclomatic/perceived complexity
- Restructure `Consolidation#decay_cycle` early return to satisfy `RunnerReturnHash` cop
- Add exception capture and logging to `Consolidation#trace_count` rescue clause

## [0.1.21] - 2026-04-01

### Changed
- `ErrorTracer.record_trace` now dispatches `Trace.shared_store` writes/flushes in a background `Thread.new` — error/fatal logging hooks no longer block the calling Puma thread, regardless of store backend (Postgres, CacheStore, or in-memory)
- Debounce check remains synchronous; only the store write and flush go async

## [0.1.20] - 2026-03-31

### Added
- CommunicationPattern sub-module for Phase C relational intelligence
- PatternAnalyzer: time-of-day/day-of-week histograms, channel preference, topic clustering, consistency scoring
- CommunicationPattern runner: update_patterns, analyze_patterns, pattern_stats
- Apollo Local persistence for communication pattern state

## [0.1.19] - 2026-03-31

### Fixed
- `postgres_store.retrieve_by_domain` now accepts `min_strength:` keyword to match in-memory store interface
- `postgres_store.all_traces` now accepts `min_strength:` keyword to match in-memory store interface
- Both methods now filter by strength in the SQL query for consistency with Store and CacheStore

## [0.1.18] - 2026-03-30

### Fixed
- fix `NameError: undefined local variable or method 'log'` in ErrorTracer.setup by replacing `log.info` with `Legion::Logging.info` — singleton module context has no `Legion::Logging::Helper` mixin

## [0.1.17] - 2026-03-30

### Changed
- update to rubocop-legion 0.1.7, resolve all offenses

## [0.1.16] - 2026-03-29

### Fixed
- Add `=> e` capture and `Legion::Logging.error` call to all bare `rescue StandardError` clauses in `memory.rb` to satisfy rescue-logging lint rule
- Fix `Lint/ShadowedException` in `snapshot.rb`: replace `rescue NameError, NoMethodError` with `rescue NameError` (`NoMethodError` is a subclass of `NameError`)
- Refactor `Snapshot#distribute_state` into dedicated helper methods to reduce cyclomatic/perceived complexity below threshold

## [0.1.15] - 2026-03-26

### Changed
- fix remote_invocable? to use class method for local dispatch

## [0.1.14] - 2026-03-26

### Fixed
- `PostgresStore#serialize_trace` and `#map_update_fields` now strip null bytes (`\x00`) from all string fields before INSERT/UPDATE. PostgreSQL text columns reject null bytes, causing `string contains null byte` errors when content from external sources (e.g., Teams Graph API) contains embedded nulls

## [0.1.13] - 2026-03-26

### Fixed
- `PostgresStore#serialize_trace` omitted `agent_id` column, causing `PG::NotNullViolation` on every insert against PostgreSQL (migration 022 declares `agent_id null: false`). Constructor now accepts `agent_id:` with fallback to `Legion::Settings.dig(:agent, :id)` or `'default'`
- `Trace.create_store` factory now resolves and passes `agent_id` to PostgresStore
- Spec schema for PostgresStore now includes `agent_id` column matching production migration

## [0.1.12] - 2026-03-26

### Fixed
- `PostgresStore#store` used SQLite-specific `insert_conflict(:replace)` which fails on PostgreSQL with `TypeError: no implicit conversion of Symbol into Integer`. Replaced with proper `insert_conflict(target: :trace_id, update: ...)` syntax that generates correct `ON CONFLICT` SQL

## [0.1.11] - 2026-03-25

### Added
- `Helpers::HotTier` module: Redis hot-tier cache in front of PostgresStore using `Legion::Cache::RedisHash`. Stores traces as Redis hashes with 24-hour TTL, maintains a sorted-set index per tenant, and provides `cache_trace`, `fetch_trace`, and `evict_trace` operations
- `PostgresStore#retrieve` checks hot tier first; falls through to DB on miss and populates hot tier on DB hit
- `PostgresStore#store` writes through to hot tier after successful DB write
- `PostgresStore#delete` evicts from hot tier before DB delete
- `PostgresStore#update` evicts stale hot-tier entry after DB update
- 32 new specs covering HotTier interface, serialize/deserialize round-trip, availability guard, and all four PostgresStore integration points

## [0.1.10] - 2026-03-25

### Added
- `Helpers::PostgresStore`: write-through durable store backed by Legion::Data (PostgreSQL or MySQL), scoped by tenant_id. Implements full store interface: store, retrieve, retrieve_by_type, retrieve_by_domain, all_traces, delete, update, record_coactivation, associations_for, walk_associations, delete_lowest_confidence, delete_least_recently_used, firmware_traces, flush (no-op), db_ready?
- `create_store` in `Trace` module now selects PostgresStore when a PostgreSQL or MySQL connection is available with both required tables; falls back to CacheStore or in-memory Store
- `postgres_available?` and `resolve_tenant_id` private helpers on `Trace` module
- 46 new specs covering all PostgresStore methods using an in-memory SQLite DB

## [0.1.9] - 2026-03-25

### Added
- Periodic actors for 10 sub-modules: Archaeology (decay), Compression (maintenance), Echo (decay), EchoChamber (decay), ImmuneMemory (decay), Nostalgia (maintenance), Palimpsest (decay), Reserve (maintenance), SemanticPriming (decay), SemanticSatiation (recovery) (closes #1)
- Quota enforcement actor for Trace (runs every 300s, calls enforce_quota) (closes #2)
- Runner methods: `decay_all` for Archaeology and EchoChamber, `enforce_quota` for Trace::Consolidation

### Fixed
- Add Mutex synchronization to trace Store and CacheStore for thread safety during concurrent tick cycles

## [0.1.7] - 2026-03-24

### Fixed
- Add Mutex synchronization to CacheStore for thread-safety across concurrent store/iterate/flush operations
- Add rescue blocks to `flush_associations` and `flush_index` for graceful handling of oversized cache entries

## [0.1.6] - 2026-03-23

### Fixed
- Fix trace migration path registration (`'memory/local_migrations'` -> `'trace/local_migrations'`)
- Refactor CacheStore from single-blob storage to per-trace individual cache keys with index, preventing OOM on flush

### Changed
- CacheStore now uses `legion:memory:trace:<uuid>` keys instead of serializing all traces into one key
- Dirty set tracking replaces dirty flag for more efficient selective flushing
- Batch flush in groups of 500 traces

## [0.1.5] - 2026-03-22

### Changed
- Add legion-logging, legion-settings, legion-json, legion-cache, legion-crypt, legion-data, legion-transport as runtime dependencies
- Update spec_helper with real sub-gem helper stubs replacing manual Legion::Logging and Helpers::Lex stubs

## [0.1.3] - 2026-03-22

### Fixed
- Fix `Trace::Helpers::Decay` crash when `last_reinforced` is a String after cache round-trip (added `ensure_time` coercion in `compute_storage_tier` and `compute_retrieval_score`)

## [0.1.2] - 2026-03-20

### Added
- `Trace::Helpers::Snapshot`: cognitive state persistence with MessagePack serialization and SHA-512/Ed25519 signing
- Snapshot save, restore, list, and prune operations with auto-prune on save
- GAIA lifecycle hooks: auto-save on `service.shutting_down`, auto-restore on `gaia.started`
- `msgpack` gem dependency

## [0.1.1] - 2026-03-18

### Changed
- Enforce NODE_TYPES validation in SemanticPriming::PrimingNetwork#add_node (returns nil for invalid types)

## [0.1.0] - 2026-03-18

### Added
- Initial release as domain consolidation gem
- Consolidated source extensions into unified domain gem under `Legion::Extensions::Agentic::<Domain>`
- All sub-modules loaded from single entry point
- Full spec suite with zero failures
- RuboCop compliance across all files
