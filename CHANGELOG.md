# Changelog

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
