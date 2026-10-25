# Blink — Manual smoke checklist

CI builds the app and runs unit tests. Global hotkeys, overlays, Screen Recording, and the pasteboard need a human on a Mac.

## Setup

1. Open `Blink.xcodeproj` in Xcode 15+.
2. Select the **Blink** scheme → **My Mac**.
3. Run (⌘R). Confirm no Dock icon (`LSUIElement`).
4. Complete onboarding (mark + Blink + one sentence → Continue).
5. Enable **Screen Recording** for Blink when prompted (or via the permissions follow-up).

## Capture → OCR → clipboard

1. Press **⌘⇧2** (or menu → **Capture**).
2. Confirm mint crosshairs + dim overlay on the active display(s).
3. Drag a rectangle over visible text (e.g. this markdown heading).
4. Release. Confirm:
   - Overlay dismisses (~120–180ms feel).
   - Menu bar glyph briefly flashes success.
   - Paste (⌘V) into TextEdit / Notes yields the expected plain text.
5. Press **⌘⇧2**, then **Esc** — overlay cancels with no clipboard change.
6. Drag a tiny (~2px) region — capture should no-op (no false clipboard write).

## Permissions failure path

1. System Settings → Privacy & Security → Screen Recording → disable Blink.
2. Press **⌘⇧2**. Confirm failure flash / menu banner; no crash.
3. Re-enable Screen Recording; capture works again.

## Open at Login

1. Menu → **Open at Login** (check on).
2. Confirm `SMAppService` registers (reopen menu → still checked).
3. Uncheck; confirm it clears.

## Experimental Hover OCR

1. Menu → **Experimental → Hover OCR: Off** → turn **On**.
2. Grant Accessibility if prompted.
3. Hover over on-screen text; mint outline appears on the hit line/word.
4. Click; text is on the clipboard.
5. Turn Hover OCR **Off**; outline and polling stop.

## Multi-display (if available)

1. ⌘⇧2 on a secondary display; drag-select text there; clipboard matches.
