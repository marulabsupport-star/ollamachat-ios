# App Store Review Response — OllamaChat v1.0

## Issue 1: Guideline 4.1(b) — Copycats

**Reviewer's Concern:** The app includes content that resembles Llama 3 without authorization.

**Our Response:**

OllamaChat is a **client application** for Ollama, an open-source local AI server. It does not include, bundle, redistribute, or represent any AI model — including Llama.

Specifically:
- OllamaChat is a **client** that connects to a user's own Ollama server instance
- The app does **not** ship with any AI model embedded or included
- When a user's Ollama server lists available models, the app displays the model names as provided by that server (via the `/api/tags` API endpoint)
- "Llama" is displayed as one of many available models that the user's own server reports — the app does not brand itself as Llama or claim any association with Meta
- The app's name, icon, and branding are entirely original and do not mimic Llama or any other brand
- We have no affiliation with Meta Platforms, Inc. or the Llama brand

The model names shown in the app (such as "llama3", "gemma", "mistral", etc.) are simply displayed as the user's Ollama server reports them. The app is a generic client — similar to how a terminal app might display names of programs installed on a remote server.

We have updated our app metadata and Privacy Policy to explicitly clarify that OllamaChat is an independent client application with no affiliation to any AI model or brand.

---

## Issue 2: Guidelines 5.1.1(i) + 5.1.2(i) — Privacy / Data Collection and Use

**Reviewer's Concern:** The app shares user data with a third-party AI service without clearly explaining what data is sent, who it's sent to, and without asking permission.

**Our Response:**

We have made the following updates to address this concern:

### 1. Privacy Consent Screen (Added)
On first launch, the app now presents a clear **Privacy Consent Screen** that explains:
- **What data is sent**: Chat messages, images (for vision models), system prompts, and search queries
- **Who data is sent to**: The user's own Ollama server, Ollama Cloud API (if API key provided), and Tavily Search API (if enabled)
- **How data is protected**: Chat history stored locally, API keys in Keychain, no analytics or tracking

The user must explicitly agree before the app proceeds to the main interface.

### 2. In-App Privacy Policy (Added)
A **Privacy Policy** page is now accessible from Settings, which includes:
- Detailed description of all data collected by the app
- Clear identification of each third-party service and what data is sent to each
- Links to each third-party service's own privacy policy
- Statement that no analytics, tracking, or advertising SDKs are used
- Contact information for questions

### 3. Privacy Policy for App Store Connect
The full privacy policy is also available at: [Add your hosted URL here]

The privacy policy identifies:
- What data the app collects (local storage only)
- How it collects data (user input stored on-device)
- All uses of data (displayed in the app, sent to user-configured servers)
- Each third-party service the app shares data with, and that those services provide equal protection per their own privacy policies

We believe these changes fully address the requirements of Guidelines 5.1.1(i) and 5.1.2(i).