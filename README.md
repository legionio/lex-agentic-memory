# lex-agentic-memory

Domain consolidation gem for memory storage, retrieval, and consolidation. Bundles 19 sub-modules into one loadable unit under `Legion::Extensions::Agentic::Memory`.

## Overview

**Gem**: `lex-agentic-memory`
**Version**: 0.1.28
**Namespace**: `Legion::Extensions::Agentic::Memory`

## Sub-Modules

| Sub-Module | Purpose |
|---|---|
| `Memory::Trace` | Memory trace storage, power-law decay, Hebbian association, tiered retrieval |
| `Memory::Episodic` | Baddeley & Hitch episodic buffer — integrates working memory channels |
| `Memory::Semantic` | Long-term conceptual knowledge — spreading activation |
| `Memory::SemanticPriming` | Prior exposure boosts retrieval speed for related concepts |
| `Memory::SemanticSatiation` | Repeated activation reduces salience — cognitive desensitization |
| `Memory::SourceMonitoring` | Attribution of memories to origin source |
| `Memory::Transfer` | Knowledge transfer between domains |
| `Memory::Archaeology` | Excavates dormant or deeply buried traces |
| `Memory::Paleontology` | Excavating old knowledge layers |
| `Memory::Palimpsest` | Layered memory overwriting — recovering original layers |
| `Memory::Compression` | Memory compression for storage efficiency |
| `Memory::Hologram` | Distributed memory storage with holographic properties |
| `Memory::Offloading` | Externalizing memory to reduce cognitive load |
| `Memory::Nostalgia` | Nostalgic retrieval bias — past warmth enhancement |
| `Memory::Echo` | Echo/resonance of past experiences |
| `Memory::EchoChamber` | Self-reinforcing memory patterns |
| `Memory::ImmuneMemory` | Immune-style memory for threat patterns |
| `Memory::Reserve` | Cognitive reserve capacity |
| `Memory::CommunicationPattern` | Tracks temporal and channel communication patterns across traces; exposes `update_patterns`, `analyze_patterns`, `pattern_stats` |

## Actors

16 actors handle autonomous background processing (all interval-based):

- `Memory::Archaeology::Actor::Decay` — every 120s
- `Memory::Compression::Actor::Maintenance` — every 300s
- `Memory::Echo::Actor::Decay` — every 60s
- `Memory::EchoChamber::Actor::Decay` — every 60s
- `Memory::Episodic::Actor::Decay` — every 15s
- `Memory::ImmuneMemory::Actor::Decay` — every 60s
- `Memory::Nostalgia::Actor::Maintenance` — every 120s
- `Memory::Palimpsest::Actor::Decay` — every 60s
- `Memory::Reserve::Actor::Maintenance` — every 60s
- `Memory::Semantic::Actor::Decay` — every 300s
- `Memory::SemanticPriming::Actor::Decay` — every 30s
- `Memory::SemanticSatiation::Actor::Recovery` — every 60s
- `Memory::SourceMonitoring::Actor::Decay` — every 60s
- `Memory::Trace::Actor::Decay` — every 60s
- `Memory::Trace::Actor::Quota` — every 300s
- `Memory::Trace::Actor::TierMigration` — every 300s

## Installation

```ruby
gem 'lex-agentic-memory'
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
