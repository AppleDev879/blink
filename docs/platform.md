# Platform choice

**Target: macOS 14.0 (Sonoma) and later.**

Reasons:

1. `SCScreenshotManager.captureImage` (ScreenCaptureKit) for region capture without standing up a full `SCStream`.
2. `SMAppService.mainApp` for Open at Login without a helper login-item target.
3. Vision + Swift concurrency baselines that match current Xcode CI images.

A CGWindowList fallback remains in `ScreenCropper` for resilience when ScreenCaptureKit fails mid-session, but the product bar is Sonoma+.
