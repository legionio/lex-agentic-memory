# lex-agentic-memory

**Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## What Is This Gem?

Domain consolidation gem for memory storage, retrieval, and consolidation. Bundles 18 source extensions into one loadable unit under `Legion::Extensions::Agentic::Memory`.

**Gem**: `lex-agentic-memory`
**Version**: 0.1.1
**Namespace**: `Legion::Extensions::Agentic::Memory`

## Sub-Modules

| Sub-Module | Source Gem | Purpose |
|---|---|---|
| `Memory::Trace` | `lex-memory` | Memory trace storage, power-law decay, Hebbian association, tiered retrieval |
| `Memory::Episodic` | `lex-episodic-buffer` | Baddeley & Hitch episodic buffer — integrates working memory channels |
| `Memory::Semantic` | `lex-semantic-memory` | Long-term conceptual knowledge — spreading activation |
| `Memory::SemanticPriming` | `lex-semantic-priming` | Prior exposure boosts retrieval speed for related concepts |
| `Memory::SemanticSatiation` | `lex-semantic-satiation` | Repeated activation reduces salience — cognitive desensitization |
| `Memory::SourceMonitoring` | `lex-source-monitoring` | Attribution of memories to origin source |
| `Memory::Transfer` | `lex-transfer-learning` | Knowledge transfer between domains |
| `Memory::Archaeology` | `lex-cognitive-archaeology` | Excavates dormant or deeply buried traces |
| `Memory::Paleontology` | `lex-cognitive-paleontology` | Excavating old knowledge layers |
| `Memory::Palimpsest` | `lex-cognitive-palimpsest` | Layered memory overwriting — recovering original layers |
| `Memory::Compression` | `lex-cognitive-compression` | Memory compression for storage efficiency |
| `Memory::Hologram` | `lex-cognitive-hologram` | Distributed memory storage with holographic properties |
| `Memory::Offloading` | `lex-cognitive-offloading` | Externalizing memory to reduce cognitive load |
| `Memory::Nostalgia` | `lex-cognitive-nostalgia` | Nostalgic retrieval bias — past warmth enhancement |
| `Memory::Echo` | `lex-cognitive-echo` | Echo/resonance of past experiences |
| `Memory::EchoChamber` | `lex-cognitive-echo-chamber` | Self-reinforcing memory patterns |
| `Memory::ImmuneMemory` | `lex-cognitive-immune-memory` | Immune-style memory for threat patterns |
| `Memory::Reserve` | `lex-cognitive-reserve` | Cognitive reserve capacity |
| `Memory::CommunicationPattern` | (inline) | Tracks temporal and channel communication patterns across traces; exposes `update_patterns`, `analyze_patterns`, and `pattern_stats` runners |

## Singleton Store Pattern

`Memory::Trace` uses a process-wide singleton store (`Memory::Trace.shared_store`). All runners share this store. Call `Memory::Trace.reset_store!` in spec `before(:each)` for test isolation.

## Actors

All actors extend `Legion::Extensions::Actors::Every` (interval-based).

| Actor | Interval | Runner / Method |
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

## Tick Integration

`Memory::Trace` maps to `memory_retrieval` (via `retrieve_and_reinforce`) and `memory_consolidation` (via `decay_cycle`) tick phases.

## Development

```bash
bundle install
bundle exec rspec        # 1804 examples, 0 failures
bundle exec rubocop      # 0 offenses
```
