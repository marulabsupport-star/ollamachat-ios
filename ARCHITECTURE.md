# ARCHITECTURE.md — Ollama Chat iOS

## Domain Map

```
┌─────────────────────────────────────────────────┐
│                     UI                           │
│  ChatScreen, SettingsScreen, RecentsScreen       │
│  @Observable ViewModels                          │
├─────────────────────────────────────────────────┤
│                   Runtime                        │
│  ApiClient, StreamParser, TavilyClient           │
│  (external communication only)                   │
├─────────────────────────────────────────────────┤
│                  Service                         │
│  ChatService, BackupService, SearchService       │
│  (business logic orchestration)                  │
├─────────────────────────────────────────────────┤
│                 Repository                       │
│  ChatRepository, SettingsRepository              │
│  (SwiftData CRUD + Keychain)                    │
├─────────────────────────────────────────────────┤
│                   Config                        │
│  ConnectionConfig, AvailableModels, AppSettings  │
│  (typed configuration, URL resolution)           │
├─────────────────────────────────────────────────┤
│                   Types                          │
│  ChatSession, ChatMessage, OllamaResponse,       │
│  DisplayModel, StreamEvent, OllamaError          │
│  (pure data, zero dependencies)                  │
└─────────────────────────────────────────────────┘
```

## Dependency Rules

**Forward-only.** Each layer imports layers below it. Never upward.

| Layer | Can Import |
|-------|-----------|
| UI | Service, Config, Types |
| Runtime | Config, Types |
| Service | Repository, Config, Types |
| Repository | Config, Types |
| Config | Types |
| Types | Foundation, SwiftData |

**Exceptions:**
- `Types` can reference `SwiftData` (`@Model` macro is structural, not behavioral)

**Forbidden:**
- Repository making HTTP calls (use Service layer)
- ViewModel calling URLSession directly (use Service layer)
- ChatMessage model knowing about ApiClient

## Cross-Cutting Concerns

| Concern | Implementation |
|---------|---------------|
| Dependency Injection | `@Environment` app-scoped singletons at root |
| Error Handling | `OllamaError` enum in Types, propagated via `throw` |
| Logging | `os.Logger` per subsystem |
| Threading | `@MainActor` on ViewModels, structured concurrency |
| Secrets | Keychain via Security framework, not UserDefaults |

## File Structure

```
OllamaChat/
├── App/
│   ├── OllamaChatApp.swift          # @main entry point
│   └── ContentView.swift             # Root navigation
├── Models/
│   ├── ChatSession.swift             # SwiftData @Model
│   ├── ChatMessage.swift             # SwiftData @Model
│   ├── DisplayModel.swift            # UI model for model picker
│   ├── StreamEvent.swift             # Sealed streaming events
│   ├── OllamaError.swift             # Error enum
│   └── BackupData.swift              # Codable backup models
├── Config/
│   ├── ConnectionConfig.swift        # Cloud vs local URL resolution
│   ├── AvailableModels.swift         # Model list singleton
│   └── AppSettings.swift             # @AppStorage wrapper
├ Repositories/
│   ├── ChatRepository.swift          # SwiftData CRUD
│   └── SettingsRepository.swift       # Keychain + UserDefaults
├── Services/
│   ├── ChatService.swift             # Chat orchestration
│   ├── BackupService.swift            # JSON export/import
│   └── SearchService.swift            # Tavily search
├── Runtime/
│   ├── ApiClient.swift                # Dual URL switching
│   ├── StreamParser.swift             # NDJSON + think-tag state machine
│   └── TavilyClient.swift             # HTTP client for Tavily
├── ViewModels/
│   ├── ChatViewModel.swift            # Main chat state
│   ├── SettingsViewModel.swift        # Settings management
│   └── SessionsViewModel.swift         # Session list
├── Views/
│   ├── ChatScreen.swift
│   ├── SettingsScreen.swift
│   ├── RecentsScreen.swift
│   └── Components/
│       ├── InputBar.swift
│       ├── MessageBubble.swift
│       ├── StreamingIndicator.swift
│       ├── ModelSelector.swift
│       ├── WelcomeCard.swift
│       ├── AttachmentMenu.swift
│       └── ThemeManager.swift
├── Theme/
│   ├── Colors.swift
│   └── Theme.swift
└── Info.plist
```

## Dual Connection Architecture

`ApiClient` maintains two connection configs:
- **Cloud**: `https://ollama.com/` + API key (from Keychain)
- **Local**: `http://192.168.x.x:11434/` (from UserDefaults, no API key)

When user selects a model:
1. Check `AvailableModels.isLocalModel(modelId)`
2. If local → `ApiClient.switchToLocal()`
3. If cloud → `ApiClient.switchToCloud()`
4. All subsequent API calls use the active config

URL normalization: IP addresses → add `http://`, hostnames → add `https://`, always append `/`.

## Streaming Architecture

```
URLSession.bytes(from: request)
    → AsyncBytes
    → AsyncLineSequence (NDJSON lines)
    → StreamParser.parseLine()
    → StreamEvent (.token, .thinking, .complete, .error)
    → ChatViewModel collects events
    → SwiftUI observes @Observable state
```

StreamParser is a **state machine** that tracks `isInsideThink` across tokens. This handles `chwitz` tags that span chunk boundaries — unlike the Android string-search approach.