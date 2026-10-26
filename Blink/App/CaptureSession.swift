import AppKit
import Foundation

/// Orchestrates overlay → capture → OCR → clipboard.
@MainActor
final class CaptureSession {
    private let overlay = CaptureOverlayController()
    private let cropper = ScreenCropper()
    private let recognizer = TextRecognizer()
    weak var statusItem: NSStatusItem?

    var isCapturing = false

    func beginCapture() {
        guard !isCapturing else { return }
        if !PermissionGate.screenRecording().isUsable {
            PermissionGate.requestScreenRecording()
            ClipboardFeedback.flashFailure(statusItem: statusItem, message: "⊘")
            return
        }

        isCapturing = true
        overlay.onComplete = { [weak self] rect in
            Task { @MainActor in
                await self?.handleSelection(rect)
            }
        }
        overlay.present()
    }

    private func handleSelection(_ rect: CGRect?) async {
        defer { isCapturing = false }
        guard let rect else { return }

        // Latch before OCR — users hold the modifier through release, not through recognition.
        let transformModifierHeld = ModifierHoldDetector.isHeld(
            PromptTransformSettings.shared.requiredModifier
        )

        do {
            let image = try await cropper.capture(rectInAppKit: rect)
            let text = try await recognizer.recognize(cgImage: image)
            let output = await CopyPipeline.copyText(
                text,
                source: .capture,
                transformModifierHeld: transformModifierHeld
            )
            ClipboardFeedback.flashSuccess(statusItem: statusItem)
            if CapturePreferences.shared.toastEnabled {
                CopyToastController.show(characterCount: output.count, selectionRect: rect)
            }
        } catch {
            AnalyticsClient.shared.track(.ocrEmptyOrFail)
            ClipboardFeedback.flashFailure(statusItem: statusItem, message: "·")
        }
    }
}
