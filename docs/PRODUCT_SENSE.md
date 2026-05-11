# PRODUCT_SENSE.md — Product Vision

## Vision

One app for local AND cloud Ollama chat. Native iOS feel, not a web wrapper. As simple as texting a smart friend.

## User Personas

1. **Local-First Liam** — Runs Ollama on their Mac/homelab. Wants private, fast, local inference. Hates janky streaming.
2. **Cloud-Casual Maya** — Uses ollama.com. Wants dead-simple onboarding. Doesn't care about local models.
3. **Power-User Priya** — Switches between local and cloud. Wants one app for both. Needs file attachments, search, and backup.

## MVP Scope — Everything In

All features from the Android app are included in v1:

| Feature | Priority |
|---------|----------|
| Streaming chat with real-time rendering | P0 |
| Local Ollama connection | P0 |
| Cloud model access | P0 |
| Think-tag parsing (reasoning models) | P0 |
| Model picker (local + cloud) | P0 |
| File attachments (photos, documents) | P1 |
| Web search (Tavily) | P1 |
| Session management with pinning | P1 |
| Backup/restore (JSON) | P1 |
| Settings (API key, URLs, model, theme, system prompt) | P1 |
| Dark/light/system theme | P1 |
| Welcome card for unconfigured users | P1 |

## Out of Scope (v2+)

- Auto-discovery of local servers (Bonjour)
- iCloud sync
- Multi-profile support
- Voice input
- Siri/Widget integration
- Push notifications

## Success Metrics

1. Time to first message < 60 seconds (cloud)
2. 7-day retention ≥ 30%
3. Streaming TTFB < 500ms (cloud)
4. Crash-free rate ≥ 99.5%
5. App Store rating ≥ 4.5 stars

## Onboarding Paths

**Cloud path**: Launch → Enter API key → Pick model → Chat
**Local path**: Launch → Enter server URL → Auto-load models → Chat

No account required for local use.