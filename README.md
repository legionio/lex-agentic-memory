# lex-agentic-memory

Domain consolidation gem for memory storage, retrieval, and consolidation. Bundles 18 source extensions into one loadable unit under `Legion::Extensions::Agentic::Memory`.

## Overview

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

## Actors

- `Memory::Episodic::Actors::Decay` — interval actor, decays episodic buffer entries
- `Memory::Semantic::Actors::Decay` — interval actor, decays semantic memory activation
- `Memory::SourceMonitoring::Actors::Decay` — interval actor, decays source monitoring confidence
- `Memory::Trace::Actors::Decay` — runs every 60s, executes `decay_cycle`
- `Memory::Trace::Actors::TierMigration` — runs every 300s, migrates traces between tiers

## Installation

```ruby
gem 'lex-agentic-memory'
```

## Development

```bash
bundle install
bundle exec rspec        # 1780 examples, 0 failures
bundle exec rubocop      # 0 offenses
```

## License

MIT
