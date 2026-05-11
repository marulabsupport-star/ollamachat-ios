# Decision Record — Ollama Chat iOS Port

_Date: 2026-05-08_
_Status: Accepted_

## Expert Consultation Summary

Four experts consulted: Architect, Product Lead, Security Engineer, Reliability Engineer.

---

## Agreements (All Experts Align)

1. **Swift 5.9+ / SwiftUI / iOS 17+ minimum** — SwiftData requires iOS 17, `@Observable` requires Swift 5.9. No reason to go lower.
2. **URLSession + Async/Await for networking** — No Alamofire. Structured concurrency handles streaming, no third-party dependency needed.
3. **SwiftData for persistence** — Native `@Model` macro, automatic migration, Room equivalent. CoreData is unnecessary overhead.
4. **MVVM + Repository pattern** — Same as Android. ViewModels observe state, Services orchestrate, Repositories persist.
5. **Keychain for secrets** — API keys in Keychain with biometric access control. Major improvement over Android's DataStore (plaintext).
6. **Forward-only dependency layers** — Types → Config → Repository → Service → Runtime → UI. No backward imports.

---

## Conflicts & Resolutions

### Conflict 1: MVP Scope — Web Search & Backup/Restore

- **Product Lead**: Defer Tavily web search and backup/restore to v1.1
- **Jason (owner)**: Everything IN. No features cut.
- **Resolution**: ✅ **All features in v1.** Tavily search, backup/restore, file attachments, advanced settings — everything from Android port.

### Conflict 2: Keychain Access Frequency

- **Security Engineer**: Load API key per-request, never cache in singleton. Biometric prompt on each read.
- **Architect**: In-memory singleton for connection config, load once from Keychain on app start.
- **Resolution**: ✅ **Hybrid approach.** Load API key from Keychain on app start and on explicit settings save. Cache in `ApiClient` during session. Re-read from Keychain on app foreground (handles biometric re-auth). Don't prompt Face ID per-request — that would be unusable for streaming chat.

### Conflict 3: Think-Tag Parsing Strategy

- **Reliability Engineer**: Character-by-character state machine to handle chunk boundaries correctly.
- **Architect**: Accumulated text + string search for `<think>` / `</think>` tags (same as Android).
- **Resolution**: ✅ **State machine approach.** Android's string search works most of the time but breaks on chunk boundaries. Use a proper state machine that tracks `isInsideThink` state across tokens. More robust, similar code complexity.

### Conflict 4: Local Server Discovery

- **Product Lead**: Auto-discover via Bonjour/local network scan.
- **Reliability Engineer**: Just use fast health check (`/api/tags` with 5s timeout).
- **Resolution**: ✅ **Health check only.** Bonjour requires `NSLocalNetworkUsageDescription` and adds complexity. A 5s health check on `/api/tags` is simpler and more reliable. Show "Connect" button that validates the URL. No background scanning.

### Conflict 5: Incremental Message Persistence

- **Reliability Engineer**: Save streaming text to DB incrementally every ~1s to prevent data loss on crash/kill.
- **Architect**: Save complete message only on stream end (`done: true`).
- **Resolution**: ✅ **Incremental save on a timer.** Save accumulated text to a "draft" message every 2 seconds during streaming. On stream completion, finalize the message. On crash recovery, show "recovered draft" if exists. This prevents the worst case (5+ minute stream lost on iOS kill) without excessive DB writes.

---

## Key Decisions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| D1 | Minimum iOS version | iOS 17.0 | SwiftData + @Observable require it |
| D2 | State management | @Observable macro | Replaces Combine, simpler than ObservableObject |
| D3 | API key storage | Keychain (not UserDefaults) | Security requirement, biometric access control |
| D4 | Streaming implementation | URLSession bytes + AsyncLineSequence | Native, no dependencies, structured concurrency |
| D5 | Think-tag parsing | State machine (not string search) | Handles chunk boundaries, more robust than Android |
| D6 | Local server discovery | Manual URL + health check | Simpler than Bonjour, reliable |
| D7 | Message persistence | Incremental save (2s interval) + finalize on done | Prevents data loss on iOS kill |
| D8 | Theme support | light/dark/system via @AppStorage | Same as Android |
| D9 | File attachments | PhotosUI + UniformTypeIdentifiers | Native, no dependencies |
| D10 | Backup format | JSON (same as Android) | Cross-platform compatible |

---

## Architecture Layers

```
Types → Config → Repository → Service → Runtime → UI
  ↑                                                    ↑
  └──────── Forward-only. No backward imports. ────────┘
```

- **Types**: Pure data models. Codable, Identifiable, @Model. Zero dependencies except Foundation/SwiftData.
- **Config**: ConnectionConfig, AvailableModels, AppSettings. Depends on Types only.
- **Repository**: SwiftData CRUD. ChatRepository, SettingsRepository. Depends on Types + Config.
- **Service**: Business logic. ChatService, BackupService, SearchService. Depends on Repository + Config + Types.
- **Runtime**: External communication. ApiClient, StreamParser, TavilyClient. Depends on Types + Config.
- **UI**: SwiftUI views + @Observable ViewModels. Depends on Service layer (not Runtime directly).

Cross-cutting: DI via @Environment, Error handling via OllamaError enum, Logging via os.Logger, Threading via @MainActor.

---

## Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| iOS kills long-running streams in background | High | Incremental save (2s). isIdleTimerDisabled during streaming. |
| Think-tag parsing across chunk boundaries | Medium | State machine instead of string search |
| Local server unreachable → 30s spin | Medium | 5s timeout health check on /api/tags |
| API key leaked in crash logs | Medium | Strip auth headers from logs. os.Logger .private for sensitive data. |
| SwiftData migration issues on schema change | Medium | Lightweight migration only. Versioned schema. |
| App Store review rejects for local network | Low | NSLocalNetworkUsageDescription in Info.plist |