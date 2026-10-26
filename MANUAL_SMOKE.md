# Blink — Manual smoke checklist

CI builds the app and runs unit tests. Global hotkeys, overlays, Screen Recording, and the pasteboard need a human on a Mac.

## Setup

1. Open `Blink.xcodeproj` in Xcode 15+.
2. Select the **Blink** scheme → **My Mac**.
3. Run (⌘R). Confirm no Dock icon (`LSUIElement`).
4. Complete onboarding (mark + Blink + one sentence → Continue).
5. Enable **Screen Recording** for Blink when prompted (or via the permissions follow-up).

## Capture → OCR → clipboard

1. Press **⌘⇧2** (or menu → **Capture** — title shows the current shortcut).
2. Confirm mint crosshairs + dim overlay on the active display(s); system pointer is hidden.
3. Drag a rectangle over visible text (e.g. this markdown heading). Crosshairs track the mouse 1:1.
4. Release. Confirm:
   - Overlay dismisses (~120–180ms feel); system pointer restored.
   - Menu bar glyph briefly flashes success.
   - Bottom-of-screen toast (“Copied · N characters”) appears ~1.5–2s on the selection display.
   - Paste (⌘V) into TextEdit / Notes yields the expected plain text.
5. Press **⌘⇧2**, then **Esc** (before or during drag) — overlay cancels, pointer restored, no clipboard change.
6. Drag a tiny (~2px) region — capture should no-op (no false clipboard write).

## Settings + shortcut

1. Menu → **Settings…**. Confirm one compact pane (Capture shortcut, Open at Login, toast, analytics, prompt transform).
2. Click the shortcut control → press a new chord (e.g. ⌘⇧3). Esc while recording cancels.
3. Confirm menu **Capture** title updates; new chord starts capture; old chord does not.
4. Toggle **Show copy toast** off → capture still copies, no toast.

## Permissions failure path

1. System Settings → Privacy & Security → Screen Recording → disable Blink.
2. Press **⌘⇧2**. Confirm failure flash / menu banner; no crash.
3. Re-enable Screen Recording; capture works again.

## Open at Login

1. Menu → **Open at Login** (check on).
2. Confirm `SMAppService` registers (reopen menu → still checked).
3. Uncheck; confirm it clears.

## Multi-display (if available)

1. ⌘⇧2 on a secondary display; drag-select text there; clipboard matches.
