# Changelog

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
