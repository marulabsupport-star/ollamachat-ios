# App Store Review Response — LLM Chat v1.0

## Issue 1: Guideline 4.1(c) — Copycats / Brand Misuse

**Reviewer's Concern:** The app name "OllamaChat" included "Ollama," a third-party brand, without authorization.

**Our Response:**

We have fully addressed this concern:

1. **App renamed from "OllamaChat" to "LLM Chat"** — The app name and all branding no longer include "Ollama" or any third-party brand name.

2. **All user-facing text updated** — Every instance of "OllamaChat" in the app UI, privacy policy, and App Store metadata has been replaced with "LLM Chat."

3. **No brand confusion** — "LLM Chat" is a generic, descriptive name that refers to the technology (Large Language Models) and does not reference or imitate any third-party brand.

4. **Bundle ID changed** — The bundle identifier has been updated from `com.marulab.ollamachat` to `com.marulab.llmchat`.

5. **Model attribution** — All AI model names displayed in the app include proper brand attribution (e.g., "Llama 3.2 (by Meta)," "Gemma 2 (by Google)," etc.) to make it clear these are third-party models, not products of this app.

---

## Issue 2: Guideline 2.1 — Performance / Demo Account

**Reviewer's Concern:** The app requires a server or API key to function, and reviewers could not test it.

**Our Response:**

We provide the following for review:

- **Demo API Key**: `[API_KEY_TO_BE_PROVIDED]`
- **How to use**: On first launch, accept the privacy consent, then go to Settings → enter the API key above → select "Cloud" mode → choose any model and start chatting.
- No self-hosted server is required. The cloud API key provides full functionality for testing.

---

## Issue 3: Guideline 1.5 — Developer Website / Support URL

**Reviewer's Concern:** The support URL was not accessible (returned 404).

**Our Response:**

The support URL is now accessible:
- **Support URL**: https://github.com/marulabsupport-star/ollamachat_ios

The GitHub repository has been made public and contains:
- Issue tracker for bug reports and questions
- README with app description and requirements

---

## Summary of Changes

| Issue | Guideline | Change |
|-------|-----------|--------|
| Brand misuse | 4.1(c) | Renamed app from "OllamaChat" to "LLM Chat"; updated all branding, bundle ID, and display strings |
| Demo access | 2.1 | Providing cloud API key for reviewer testing |
| Support URL | 1.5 | Made GitHub support repo public |

All changes have been applied and the app is ready for re-review.