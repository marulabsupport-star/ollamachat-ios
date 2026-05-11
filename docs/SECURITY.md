# SECURITY.md — Security Model

## Authentication

- **Device-level only.** Single-user app. No server-side identity.
- **Biometric lock** (Face ID/Touch ID) optional on app launch via `LAContext`.
- **Cloud auth** = API key stored in Keychain. No user accounts.

## Secrets Management

| Secret | Storage | Access Level |
|--------|---------|-------------|
| Ollama Cloud API Key | Keychain | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` + `kSecAccessControlBiometryAny` |
| Tavily API Key | Keychain | Same as above |
| Chat History | SwiftData | `NSFileProtectionComplete` |
| Settings (URLs, theme) | UserDefaults | No protection needed (not secrets) |

**Rules:**
- Never log API keys. Strip auth headers from error logs.
- Load keys from Keychain on app start and settings save. Cache in ApiClient during session.
- Re-read on app foreground (triggers biometric re-auth).
- `ThisDeviceOnly` prevents iCloud/iTunes backup of keys.
- Backup exports exclude API keys by default.

## Data Boundaries

### Inbound
- **API responses**: Validate with Codable strict decoding. Set max response size.
- **File attachments**: Validate MIME type + extension. Max 20MB. Use PHPickerViewController (scoped access).
- **Backup imports**: Schema-versioned JSON. Validate before import. Reject unknown fields.
- **Server URL config**: Block `file://`, `data://`, `ftp://`. Only `http://` and `https://`.

### Outbound
- **Chat messages**: Sent to user-configured server. Warn on HTTP (unencrypted).
- **Web search queries**: HTTPS to Tavily. PII risk — user aware via UI toggle.
- **Backup exports**: Exclude API keys. Full chat data — user chooses share destination.

## Threat Model

| Threat | Risk | Mitigation |
|--------|------|------------|
| API key leaked via backup | Critical | Exclude from exports, Keychain ThisDeviceOnly |
| Unencrypted local traffic | High | Warning on HTTP, never send API keys over HTTP |
| Device lost/stolen | High | NSFileProtectionComplete, biometric lock |
| Malicious backup import | Medium | Schema validation, field allowlisting |
| Crash logs with API keys | Medium | Strip auth headers, os.Logger .private |

## Security Invariants

1. API keys are NEVER stored outside Keychain
2. API keys are NEVER included in logs, crash reports, or backups
3. Local HTTP connections are ALWAYS warned to the user
4. SwiftData files use NSFileProtectionComplete
5. File attachments use scoped access (PHPickerViewController), never full photo library