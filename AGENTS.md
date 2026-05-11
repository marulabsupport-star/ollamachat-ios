# AGENTS.md — Ollama Chat iOS

Chat with Ollama AI models (local + cloud) on iOS. Native SwiftUI app.

## Quick Start

```bash
# Open in Xcode
open OllamaChat.xcodeproj

# Run on simulator
# Xcode → Product → Run (⌘R)

# Tests
# Xcode → Product → Test (⌘U)
```

## Architecture

MVVM + Repository. 6 layers, forward-only dependencies.

```
Types → Config → Repository → Service → Runtime → UI
```

See [ARCHITECTURE.md](../ARCHITECTURE.md) for full layer details and dependency rules.

## Key Conventions

- **Swift 5.9+ / iOS 17+ / SwiftUI / SwiftData** — no lower targets, no exceptions
- **No third-party dependencies** — URLSession, SwiftData, PhotosUI, os.Logger cover everything
- **API keys in Keychain** — never UserDefaults, never SwiftData, never logs
- **State machine for think-tag parsing** — not string search, handles chunk boundaries
- **Incremental message save** — every 2s during streaming, finalize on done
- **@Observable macro** — not ObservableObject/Combine, for state management
- **@MainActor on ViewModels** — all UI state updates on main thread
- **Forward-only imports** — lower layers never import upper layers

## Key Files

- `ARCHITECTURE.md` — Domain map and dependency rules
- `docs/design-docs/decision-record.md` — All architectural decisions
- `docs/DESIGN.md` — Design principles
- `docs/SECURITY.md` — Security model
- `docs/RELIABILITY.md` — Reliability invariants

## Feature Parity with Android

Streaming chat, local/cloud model switching, think-tag parsing, file attachments, web search (Tavily), backup/restore, session pinning, dark/light/system theme, advanced settings (system prompt, temperature, max tokens).