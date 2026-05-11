# DESIGN.md — Design Principles

## Principles

1. **Boring tech wins.** URLSession, SwiftData, Keychain — all first-party. No third-party dependencies unless absolutely necessary.
2. **State machine over string search.** Think-tag parsing, streaming state — use explicit state machines, not regex hacks.
3. **Incremental persistence.** Never lose data. Save streaming messages every 2s. Finalize on completion.
4. **Parse at boundaries.** Validate all external data (API responses, file imports, backup JSON) at the point of entry. Trust nothing outside the app.
5. **Forward-only dependencies.** Lower layers never import upper layers. Enforce mechanically.
6. **iOS-native UX.** Swipe gestures, haptics, share sheet, biometrics — not a direct Android translation.
7. **Keychain for secrets, UserDefaults for settings.** Never the reverse. Never SwiftData for secrets.

## Patterns

### MVVM + Repository
- **View**: SwiftUI views. Observe ViewModel. Never call Repository directly.
- **ViewModel**: `@Observable` class. `@MainActor`. Calls Service layer.
- **Service**: Business logic orchestration. Calls Repository + Runtime.
- **Repository**: Data persistence. SwiftData CRUD + Keychain access.
- **Runtime**: External communication. URLSession, streaming.

### Error Propagation
- `OllamaError` enum in Types layer.
- `throw` through async/await chain.
- ViewModel catches and sets `errorMessage` state.
- View shows alert or inline error card.

### Configuration Switching
- `ApiClient` holds cloud/local configs.
- `switchForModel(_:)` auto-switches based on model ID.
- Settings changes update config immediately (no restart needed).

### Message Flow
1. User types → ViewModel.sendMessage()
2. ViewModel saves user message via Repository
3. ViewModel calls ChatService.stream()
4. ChatService calls ApiClient → StreamParser → emits StreamEvents
5. ViewModel updates @Observable state on each event
6. SwiftUI auto-renders via observation
7. On completion: Repository saves complete message
8. On error: Repository saves partial message (if any)