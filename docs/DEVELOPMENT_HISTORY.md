# OllamaChat-iOS Development History

> Project: **OllamaChat-iOS** — iOS port of Ollama Cloud Chat (Android)
> Bundle ID: `com.openclaw.ollamachat`
> Target: iOS 17+, Swift 5.9+, SwiftUI, SwiftData, zero third-party dependencies

## Architecture

6-layer architecture:
1. **App** — OllamaChatApp (entry), ContentView (navigation shell)
2. **Config** — AppSettings, AvailableModels, ConnectionConfig
3. **Models** — ChatMessage, ChatSession, DisplayModel, OllamaModels, OllamaError
4. **Repositories** — ChatRepository (SwiftData), SettingsRepository (Keychain/UserDefaults)
5. **Services** — ChatService (streaming), SearchService (Tavily), BackupService
6. **Views** — ChatScreen, SettingsScreen, RecentsScreen + Components

## Key Files Modified

| File | Purpose |
|------|---------|
| `App/ContentView.swift` | Navigation, session loading, ChatViewModel as @State |
| `App/OllamaChatApp.swift` | Static settings/connectionConfig for global access |
| `Config/AppSettings.swift` | Default model, theme, search mode settings |
| `Config/AvailableModels.swift` | Dynamic model fetching, vision capability detection via /api/show |
| `Config/ConnectionConfig.swift` | Local server URL, Cloudflare tunnel normalization |
| `Models/DisplayModel.swift` | UI model with `supportsVision` (from API, not hardcoded patterns) |
| `Models/OllamaModels.swift` | OllamaShowResponse, StringValue, OllamaMessage custom encoder |
| `Models/ChatMessage.swift` | SwiftData model with hasImages |
| `Models/ChatSession.swift` | SwiftData session model |
| `Repositories/ChatRepository.swift` | updateMessageInMemory (streaming), addMessage(hasImages:) |
| `Repositories/SettingsRepository.swift` | Keychain on device, UserDefaults on simulator |
| `Services/ChatService.swift` | Streaming with in-memory updates, image support, empty text→"Describe this image." |
| `Services/SearchService.swift` | Tavily search with Korean keyword detection |
| `ViewModels/ChatViewModel.swift` | Chat state, vision warning, model picker state |
| `Views/ChatScreen.swift` | Main chat UI, VisionWarningBanner, ModelPickerSheet, attachment pickers |
| `Views/Components/InputBar.swift` | Input bar, AttachmentManager, AttachmentPreviewRow, PDFRenderer |
| `Views/Components/MessageBubble.swift` | Message rendering, CodeBlock with Run button, WebView |
| `Views/Components/BackupRestoreScreen.swift` | Export/Import with ShareSheetView |
| `Views/RecentsScreen.swift` | Session list, empty chat filtering |
| `Views/SettingsScreen.swift` | API key, local server, test connection, backup/restore |

## Features Implemented

### Core
- [x] Ollama Cloud + Local server chat with streaming
- [x] Dynamic model fetching from `/api/tags` (Cloud + Local)
- [x] Model groups: Local / Cloud (no sub-categories)
- [x] Chat sessions with SwiftData persistence
- [x] Model selection persistence across navigation

### Web Search
- [x] Auto/Always/Off modes
- [x] Korean keyword detection
- [x] Search results injected as system prompt

### Code Execution
- [x] Code block renderer with Run button (HTML/CSS/JS)
- [x] In-app WebView for running code
- [x] JavaScript console.log output display
- [x] Copy button on all code blocks

### Attachments & Vision
- [x] Photo picker (PHPicker) + Document picker
- [x] Image attachment with base64 encoding to Ollama API
- [x] PDF analysis (render pages to JPEG, send to vision model)
- [x] **Vision model detection via /api/show capabilities** (not hardcoded patterns)
  - Local models: `families` contains "clip" → vision
  - Cloud models: `/api/show` → `capabilities` contains "vision"
  - Fallback: `OllamaModelDetails.supportsVision` checks families
- [x] Vision warning banner when attaching images to non-vision model
- [x] 👁️ icon on vision-capable models in model picker
- [x] "Switch to a vision model" button in warning banner

### Streaming
- [x] In-memory updates (no SwiftData save per token)
- [x] Periodic saves every 2s
- [x] Final save on stream complete

### Settings
- [x] API key (Keychain on device, UserDefaults on simulator)
- [x] Local server URL with Cloudflare tunnel normalization
- [x] Test Connection button
- [x] Backup/Export with Share Sheet
- [x] Import/Restore

## Key Decisions

1. **Vision detection**: Changed from hardcoded name patterns to API-based detection via `/api/show` capabilities. This correctly identifies kimi-k2.6, gemma3/4, llava, etc. without code updates for new models.

2. **Keychain on device, UserDefaults on simulator**: Simulator Keychain has known persistence issues.

3. **Streaming performance**: `updateMessageInMemory()` for token-by-token updates, `updateMessage()` with save only for periodic (2s) and final saves.

4. **Static OllamaChatApp settings**: Allows global access without @Environment.

5. **ChatViewModel as @State**: Prevents SwiftUI from recreating ViewModel on navigation changes.

6. **OllamaMessage custom encoder**: Omits `images` key when nil/empty to avoid sending `"images": []` to API.

7. **Empty text + image**: Auto-inserts "Describe this image." as content.

8. **PDF rendering**: Uses `CGContext.drawPDFPage()` (not `CGPDFPage.draw(in:)` which conflicts with SwiftUI View).

## Cloudflare Tunnel

- URL: `https://determination-now-collect-trout.trycloudflare.com`
- Uses https without port (no :11434 auto-append)

## Local Models

- `gemma3:4b` (3.3GB, vision-capable) ✅ vision
- `llama3.2:3b` (2GB, text-only) ❌ no vision
- `gpt-oss:20b` (13.8GB) ❌ no vision

## Cloud Models (examples)

- `kimi-k2.5:cloud` ✅ vision (via /api/show capabilities)
- `nemotron-3-super:cloud` — capabilities unknown
- `gemini-3-flash-preview:latest` — capabilities unknown