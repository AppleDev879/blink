# Blink

<p align="center">
  <img src="docs/blink-mark.jpg" alt="Blink mark — mint crosshair on charcoal" width="128" height="128" />
</p>

**Select any part of your screen. Get the text.**

Blink is a macOS menu-bar OCR tool. Press **⌘⇧2**, drag a region on any display, and the recognized plain text is copied to your clipboard. No Dock icon. Quiet by design.

> **Platform:** macOS **14+** (Sonoma). Uses ScreenCaptureKit + Vision. The deployment target is 14 so `SCScreenshotManager` and `SMAppService.mainApp` are available without shims.

## Features

| | |
| --- | --- |
| **⌘⇧2 capture** | Crosshairs overlay → drag-select → OCR → clipboard |
| **Menu bar** | Capture, Experimental Hover OCR, Open at Login, Quit |
| **Open at Login** | `SMAppService` toggle |
| **Onboarding** | One brand screen, then Screen Recording / Accessibility prompts |
| **Experimental: Hover OCR** | Opt-in. Outlines text near the cursor; click copies. Gated under **Experimental** in the menu |

## Build & run

```bash
open Blink.xcodeproj
```

Or from the CLI:

```bash
xcodebuild -scheme Blink -configuration Debug -destination 'platform=macOS' build
xcodebuild -scheme Blink -configuration Debug -destination 'platform=macOS' test
```

Run the app from Xcode (⌘R). Grant **Screen Recording** when prompted (required for capture). **Accessibility** is only needed for Experimental click-to-copy across other apps.

Unsigned local builds: System Settings → Privacy & Security may ask you to allow Blink after the first launch.

## Permissions

| Permission | Why |
| --- | --- |
| **Screen Recording** | Capture the framed region (and Experimental hover region) |
| **Accessibility** | Optional — Experimental hover OCR click-to-copy in other apps |

If Screen Recording is off, the menu shows an actionable banner that opens System Settings.

## Experimental Hover OCR

Off by default. Enable **Experimental → Hover OCR** in the menu bar. Blink periodically OCRs a small region around the pointer, draws a mint outline on the hit text, and copies it on click. Expect higher CPU while enabled; turn it off when you don’t need it.

## Tests & CI

- Unit tests cover hotkey parsing, OCR text normalization, and selection geometry (`BlinkTests`).
- GitHub Actions (`.github/workflows/ci.yml`) builds and runs tests on `macos-latest` for every push/PR.
- Overlay + global hotkey + clipboard cannot be fully driven in CI — see [MANUAL_SMOKE.md](MANUAL_SMOKE.md).

## License

MIT — see [LICENSE](LICENSE).
