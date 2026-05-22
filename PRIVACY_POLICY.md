# OllamaChat Privacy Policy

**Last updated: May 2026**

## 1. Overview

OllamaChat ("the App") is a client application that connects to Ollama servers. The App itself does not collect, store, or transmit any personal data to its developer. All data processing occurs between your device and the Ollama server you choose to connect to.

## 2. Data Collected by the App

- **Chat messages**: Stored locally on your device using SwiftData. Not transmitted to the app developer.
- **API keys**: Stored securely in your device's Keychain. Never sent anywhere except the server they are intended for.
- **Server URLs**: Stored locally in UserDefaults to remember your configuration.
- **Settings preferences** (theme, default model, etc.): Stored locally in UserDefaults.

## 3. Data Shared with Third-Party Services

When you use the App, data is sent to third-party services that **you configure**:

### 3.1 Ollama Server (Local or Cloud)
- **Who**: Your own Ollama server, at the address you specify
- **What is sent**: Chat messages, prompts, images (when using vision-capable models), system prompts
- **Purpose**: To generate AI responses to your queries
- **Your control**: You choose the server address and can change it at any time

### 3.2 Ollama Cloud API
- **Who**: Ollama, Inc. (https://ollama.com)
- **What is sent**: Chat messages, prompts, images (when using vision-capable models), API key for authentication
- **Purpose**: To access cloud-hosted AI models
- **Your control**: Only active if you provide an API key; you can remove it at any time

### 3.3 Tavily Search API
- **Who**: Tavily, Inc. (https://tavily.com)
- **What is sent**: Search queries derived from your messages
- **Purpose**: To provide web search results for grounded responses
- **Your control**: Only active if you provide a Tavily API key and enable web search

## 4. Your Consent

Before any data is sent to a third-party service, the App clearly explains what data will be sent and to whom, and asks for your explicit permission. You can review and change your server configuration at any time in Settings.

## 5. Data Retention

- **Local chat history**: Stored on your device until you delete it. You can clear all data in Settings → Clear All Chat Data.
- **API keys**: Stored in Keychain until you delete them from Settings.
- **Third-party services**: Data retention is governed by each service's own privacy policy.

## 6. Third-Party Privacy Policies

- [Ollama Privacy Policy](https://ollama.com/privacy)
- [Tavily Privacy Policy](https://tavily.com/privacy)

## 7. No Tracking or Analytics

The App does not include any analytics, tracking, or advertising SDKs. The App developer has no access to your data, conversations, or server configurations.

## 8. Children's Privacy

The App is not directed at children under 13. The App does not knowingly collect personal information from children.

## 9. Changes to This Policy

This privacy policy may be updated from time to time. Changes will be reflected in the "Last updated" date. Continued use of the App after changes constitutes acceptance of the updated policy.

## 10. Contact

If you have questions about this privacy policy or your data, please contact:

**marulabsupport@gmail.com**

---

*This privacy policy applies to the OllamaChat iOS application only. The App is a client for Ollama, an open-source AI server. It does not include, redistribute, or represent any AI model including Llama, which is a trademark of Meta Platforms, Inc.*