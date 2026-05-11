# RELIABILITY.md — Reliability Invariants

## Error Handling Strategy

- **Network errors**: Retry with exponential backoff (2s, 4s, 8s max). Show inline error with retry button.
- **Streaming interruptions**: Save partial message. Show "Connection lost" banner. Auto-reconnect if possible.
- **Local server unreachable**: 5s timeout on `/api/tags` health check. Show "Server not found" immediately, don't spin.
- **Malformed API responses**: Skip line, continue parsing. Log warning. Never crash on bad JSON.

## Observability

- `os.Logger` with subsystem `"com.openclaw.ollamachat"` per domain
- Categories: `network`, `streaming`, `persistence`, `ui`
- No third-party crash reporters. Use iOS MetricKit for crash-free metrics.
- Debug builds: verbose logging. Release builds: errors and warnings only.

## SLOs

| Metric | Target |
|--------|--------|
| Time to first token (cloud) | < 500ms |
| Local server health check | < 5s (timeout) |
| Streaming message save interval | Every 2s |
| Crash-free rate | ≥ 99.5% |
| App launch to chat ready | < 2s |

## Failure Modes

| # | Failure | Detection | Recovery |
|---|---------|-----------|----------|
| 1 | iOS kills app during streaming | App lifecycle delegate | Incremental save every 2s. Recover draft on next launch. |
| 2 | Local server goes offline mid-chat | URLSession error | Show inline banner. Queue message. Retry on reconnect. |
| 3 | Cloud API rate limit | HTTP 429 | Exponential backoff. Show "Rate limited" message. |
| 4 | SwiftData corruption | ModelContext error | Graceful fallback. Offer reset. Never silent data loss. |
| 5 | Network transition (WiFi→cellular) | NWPathMonitor | Auto-switch reachable endpoint. Pause streaming, resume. |

## Data Integrity

- **Streaming messages**: Saved every 2s to SwiftData as draft. Finalized on `done: true`.
- **Crash recovery**: On app launch, check for draft messages. Show "Recover unsaved message?" dialog.
- **Backup import**: Schema version check. Reject unknown versions. Import into isolated context, validate, then merge.
- **Concurrent access**: SwiftData handles this via ModelContext. No manual locking needed.

## Deployment Safety

- **TestFlight** for beta testing before App Store
- **No force updates** — version check is advisory only
- **SwiftData migrations**: Lightweight only. No custom migration policies for v1.
- **App Store review**: Include NSLocalNetworkUsageDescription in Info.plist for local server access.

## Reliability Invariants

1. Streaming messages are saved incrementally — never lose more than 2 seconds of content
2. Local server unreachability is detected within 5 seconds — never spin indefinitely
3. Partial messages are always recoverable after a crash
4. The app never crashes on malformed server responses
5. Backup imports are validated before any data is modified