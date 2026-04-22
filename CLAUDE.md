# lex-agentic-memory

**Parent**: `../CLAUDE.md`

## What Is This Gem?

Domain consolidation gem for memory storage, retrieval, and consolidation. Bundles 19 sub-modules into one loadable unit under `Legion::Extensions::Agentic::Memory`.

**Gem**: `lex-agentic-memory`
**Version**: 0.1.28
**Namespace**: `Legion::Extensions::Agentic::Memory`

## Sub-Modules

| Sub-Module | Source Gem | Purpose | Runner Methods |
|---|---|---|---|
| `Memory::Trace` | `lex-memory` | Memory trace storage, power-law decay, Hebbian association, tiered retrieval | `store`, `retrieve`, `reinforce`, `decay_cycle`, `enforce_quota`, `migrate_tier`, `consolidate`, `batch_decay` |
| `Memory::Episodic` | `lex-episodic-buffer` | Baddeley & Hitch episodic buffer — integrates working memory channels | `update_episodic_buffer`, `retrieve_episode` |
| `Memory::Semantic` | `lex-semantic-memory` | Long-term conceptual knowledge — spreading activation | `update_semantic_memory`, `retrieve_concept` |
| `Memory::SemanticPriming` | `lex-semantic-priming` | Prior exposure boosts retrieval speed for related concepts | `prime`, `decay`, `priming_status` |
| `Memory::SemanticSatiation` | `lex-semantic-satiation` | Repeated activation reduces salience — cognitive desensitization | `saturate`, `recover`, `satiation_status` |
| `Memory::SourceMonitoring` | `lex-source-monitoring` | Attribution of memories to origin source | `update_source_monitoring`, `attribute_source` |
| `Memory::Transfer` | `lex-transfer-learning` | Knowledge transfer between domains | `transfer_learning` |
| `Memory::Archaeology` | `lex-cognitive-archaeology` | Excavates dormant or deeply buried traces | `decay_all`, `excavate` |
| `Memory::Paleontology` | `lex-cognitive-paleontology` | Excavating old knowledge layers | `cognitive_paleontology` |
| `Memory::Palimpsest` | `lex-cognitive-palimpsest` | Layered memory overwriting — recovering original layers | `decay_all_ghosts`, `write_layer` |
| `Memory::Compression` | `lex-cognitive-compression` | Memory compression for storage efficiency | `compress_all`, `decompress` |
| `Memory::Hologram` | `lex-cognitive-hologram` | Distributed memory storage with holographic properties | `cognitive_hologram` |
| `Memory::Offloading` | `lex-cognitive-offloading` | Externalizing memory to reduce cognitive load | `cognitive_offloading` |
| `Memory::Nostalgia` | `lex-cognitive-nostalgia` | Nostalgic retrieval bias — past warmth enhancement | `age_memories`, `recall`, `analysis` |
| `Memory::Echo` | `lex-cognitive-echo` | Echo/resonance of past experiences | `decay_all`, `echo_status` |
| `Memory::EchoChamber` | `lex-cognitive-echo-chamber` | Self-reinforcing memory patterns | `decay_all`, `echo_chamber_status` |
| `Memory::ImmuneMemory` | `lex-cognitive-immune-memory` | Immune-style memory for threat patterns | `decay_all`, `cognitive_immune_memory` |
| `Memory::Reserve` | `lex-cognitive-reserve` | Cognitive reserve capacity | `update_cognitive_reserve`, `reserve_status` |
| `Memory::CommunicationPattern` | (inline) | Tracks temporal and channel communication patterns across traces | `update_patterns`, `analyze_patterns`, `pattern_stats` |

## Singleton Store Pattern

`Memory::Trace` uses a process-wide singleton store (`Memory::Trace.shared_store`). All runners share this store. Call `Memory::Trace.reset_store!` in spec `before(:each)` for test isolation.

## Actors

All actors extend `Legion::Extensions::Actors::Every` (interval-based).

| Actor | Interval | Target Method |
|---|---|---|
| `Memory::Archaeology::Actor::Decay` | 120s | `CognitiveArchaeology#decay_all` |
| `Memory::Compression::Actor::Maintenance` | 300s | `CognitiveCompression#compress_all` |
| `Memory::Echo::Actor::Decay` | 60s | `CognitiveEcho#decay_all` |
| `Memory::EchoChamber::Actor::Decay` | 60s | `CognitiveEchoChamber#decay_all` |
| `Memory::Episodic::Actor::Decay` | 15s | `EpisodicBuffer#update_episodic_buffer` |
| `Memory::ImmuneMemory::Actor::Decay` | 60s | `CognitiveImmuneMemory#decay_all` |
| `Memory::Nostalgia::Actor::Maintenance` | 120s | `Recall#age_memories` |
| `Memory::Palimpsest::Actor::Decay` | 60s | `CognitivePalimpsest#decay_all_ghosts` |
| `Memory::Reserve::Actor::Maintenance` | 60s | `CognitiveReserve#update_cognitive_reserve` |
| `Memory::Semantic::Actor::Decay` | 300s | `SemanticMemory#update_semantic_memory` |
| `Memory::SemanticPriming::Actor::Decay` | 30s | `SemanticPriming#decay` |
| `Memory::SemanticSatiation::Actor::Recovery` | 60s | `SemanticSatiation#recover` |
| `Memory::SourceMonitoring::Actor::Decay` | 60s | `SourceMonitoring#update_source_monitoring` |
| `Memory::Trace::Actor::Decay` | 60s | `Consolidation#decay_cycle` |
| `Memory::Trace::Actor::Quota` | 300s | `Consolidation#enforce_quota` |
| `Memory::Trace::Actor::TierMigration` | 300s | `Consolidation#migrate_tier` |

## Dependencies

| Gem | Purpose |
|---|---|
| `legion-cache` >= 1.3.11 | Cache access |
| `legion-data` >= 1.4.17 | DB persistence (Trace local migrations for `memory_traces`, `memory_associations`) |
| `legion-json` >= 1.2.1 | JSON serialization |
| `legion-logging` >= 1.3.2 | Logging |
| `legion-settings` >= 1.3.14 | Settings |
| `legion-transport` >= 1.3.9 | AMQP |
| `msgpack` ~> 1.7 | Binary serialization for trace payloads |

## Key Constants

- `Memory::Trace` local migrations: `20260316000001_create_memory_traces`, `20260316000002_create_memory_associations`

## Tick Integration

- `Memory::Trace` maps to `memory_retrieval` (via `retrieve_and_reinforce`) and `memory_consolidation` (via `decay_cycle`) tick phases.

## Development

```bash
bundle install
bundle exec rspec        # 0 failures
bundle exec rubocop      # 0 offenses
```
