# Blink

<p align="center">
  <img src="docs/blink-mark.jpg" alt="Blink mark — mint crosshair on charcoal" width="128" height="128" />
</p>

**Select any part of your screen. Get the text.**

Blink is a macOS menu-bar OCR tool. Press **⌘⇧2** (configurable), drag a region on any display, and the recognized plain text is copied to your clipboard — with a quiet bottom toast. No Dock icon. Quiet by design.

> **Platform:** macOS **14+** (Sonoma). Uses ScreenCaptureKit + Vision. The deployment target is 14 so `SCScreenshotManager` and `SMAppService.mainApp` are available without shims.

## Features

| | |
| --- | --- |
| **Capture** | ⌘⇧2 by default (change in Settings) → crosshairs → OCR → clipboard + toast |
| **Menu bar** | Capture, Open at Login, Settings…, Check for Updates…, Quit |
| **Auto-updates** | [Sparkle 2](https://sparkle-project.org/) via GitHub Releases appcast (direct distribution) |
| **Open at Login** | `SMAppService` toggle |
| **Onboarding** | One brand screen, then Screen Recording prompt |
| **Analytics** | Opt-in anonymous TelemetryDeck signals (off by default) |
| **Prompt transform** | Free via BYOK or local Ollama — hold ⌃ (configurable) at copy time. Blink never bills for tokens. |

## Shortcuts

| Shortcut | Action |
| --- | --- |
| **⌘⇧2** (default) | Start capture (crosshairs overlay). Change under Settings → Capture shortcut. |
| **Esc** | Cancel capture — dismiss overlay, no OCR, no clipboard change. While recording a new shortcut in Settings, Esc cancels recording. |

Menu → **Capture** shows the current chord. If registration fails (conflict), Blink stays quiet and Settings shows a short hint.

While the overlay is up, the system pointer is hidden; mint crosshairs track the mouse 1:1 until you release a selection, press Esc, or the session ends. After a successful copy, a brief bottom-of-screen toast confirms (toggle in Settings).

## Build & run

```bash
open Blink.xcodeproj
```

Or from the CLI:

```bash
xcodebuild -scheme Blink -configuration Debug -destination 'platform=macOS' build
xcodebuild -scheme Blink -configuration Debug -destination 'platform=macOS' test
```

Run the app from Xcode (⌘R). Grant **Screen Recording** when prompted (required for capture).

Unsigned local builds: System Settings → Privacy & Security may ask you to allow Blink after the first launch.

## Permissions

| Permission | Why |
| --- | --- |
| **Screen Recording** | Capture the framed region |

If Screen Recording is off, the menu shows an actionable banner that opens System Settings.

## Analytics (opt-in)

Off by default. Settings → **Share anonymous analytics**. Signals are TelemetryDeck-compatible event names only (app launch, capture completed, OCR empty/fail, open-at-login toggled, prompt-transform used). No OCR text, no prompts, no keys.

### TelemetryDeck App ID

1. Create an app at [TelemetryDeck](https://telemetrydeck.com) and copy the App ID.
2. Locally:

```bash
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
# edit Config/Secrets.xcconfig — set BLINK_TELEMETRYDECK_APP_ID
```

`Config/Secrets.xcconfig` is gitignored. `Blink/Info.plist` reads `$(BLINK_TELEMETRYDECK_APP_ID)` via `Config/Shared.xcconfig`. Without a real App ID, the toggle does nothing harmful — signals are skipped.

## Free + LLM (prompt transform)

Core capture (OCR → clipboard) stays free forever. Optional ⌃-held transforms use **your** API key or a **local** model — Blink doesn’t bill for tokens and does not ship a hosted credits proxy.

Settings → **Prompt transform** → provider:

| Provider | What it does |
| --- | --- |
| **Off** | ⌃-held transform disabled; capture always copies raw OCR |
| **BYOK** | OpenAI-compatible Keychain key + endpoint/model; optional **Validate** dry-run |
| **Local (Ollama)** | Default `http://localhost:11434` (chat via `/v1`); detect reachability, list models, **Use local model** |

Template uses `{{text}}`. At capture release: if the provider is armed and the modifier is held, Blink runs the prompt and copies the model reply. No key / Ollama down / Off → raw OCR + one quiet menu hint. Never an error modal.

### Try BYOK

1. Settings → Provider **BYOK** → paste an OpenAI-compatible API key → **Save API Key**.
2. Set endpoint/model (defaults: `https://api.openai.com/v1`, `gpt-4o-mini`) → optional **Validate**.
3. Capture a region while holding **⌃** — clipboard gets the model reply.

### Try Ollama locally

1. Install and run [Ollama](https://ollama.com); pull a model (`ollama pull llama3.2`).
2. Settings → Provider **Local (Ollama)** → wait for “Ollama reachable” → pick a model (or **Use local model**).
3. Capture while holding **⌃**. If Ollama isn’t running, Blink copies raw OCR quietly.

## Auto-updates (Sparkle)

Direct (non–Mac App Store) builds check for updates against:

`https://github.com/AppleDev879/blink/releases/latest/download/appcast.xml`

Menu bar → **Check for Updates…**. Quiet background checks are enabled (daily). Before shipping updates you must generate EdDSA keys, put the **public** key in `SUPublicEDKey`, and never commit the private key. Full release recipe (notarize → `sign_update` → GitHub Release + appcast): [docs/sparkle-setup.md](docs/sparkle-setup.md). Sample feed: [sparkle/appcast.example.xml](sparkle/appcast.example.xml).

## Tests & CI

- Unit tests cover hotkey parsing, OCR text normalization, selection geometry, prompt template interpolation, and modifier flag parsing (`BlinkTests`).
- GitHub Actions (`.github/workflows/ci.yml`) builds and runs tests on `macos-latest` for every push/PR.
- Overlay + global hotkey + clipboard cannot be fully driven in CI — see [MANUAL_SMOKE.md](MANUAL_SMOKE.md).
- Tests do not exercise network update checks.

## License

MIT — see [LICENSE](LICENSE).
