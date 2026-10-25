import AppKit
import Foundation
import Vision

/// Experimental: OCR near the cursor, outline text under the pointer, click to copy.
/// Opt-in only. Uses a local capture region + Vision; requires Screen Recording.
/// Click-to-copy uses a global event monitor (Accessibility recommended).
@MainActor
final class CursorTipOCRController: ObservableObject {
    @Published var isEnabled = false
    @Published private(set) var outlinedText: String?

    private var pollTimer: Timer?
    private var clickMonitor: Any?
    private var outlineWindow: OutlineWindow?
    private let cropper = ScreenCropper()
    private let recognizer: TextRecognizer = {
        let r = TextRecognizer()
        r.recognitionLevel = .fast
        r.usesLanguageCorrection = false
        r.minimumConfidence = 0.4
        return r
    }()

    private var lastPoint: CGPoint = .zero
    private var inFlight = false
    private var currentHit: Hit?
    weak var statusItem: NSStatusItem?

    private struct Hit {
        var text: String
        var rect: CGRect // AppKit global
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled {
            start()
        } else {
            stop()
        }
    }

    private func start() {
        stopMonitorsOnly()
        guard PermissionGate.screenRecording().isUsable else {
            PermissionGate.requestScreenRecording()
            isEnabled = false
            return
        }

        outlineWindow = OutlineWindow()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.tick()
            }
        }
        // Local + global click. Global needs Accessibility for other apps.
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.handleClick()
            }
        }
        if PermissionGate.accessibility() != .granted {
            // Still useful with local monitor for clicks on our outline; prompt once.
            PermissionGate.requestAccessibility()
        }
    }

    private func stop() {
        stopMonitorsOnly()
        outlinedText = nil
        currentHit = nil
    }

    private func stopMonitorsOnly() {
        pollTimer?.invalidate()
        pollTimer = nil
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
        outlineWindow?.orderOut(nil)
        outlineWindow = nil
    }

    private func handleClick() {
        guard let hit = currentHit else { return }
        ClipboardFeedback.copy(hit.text)
        ClipboardFeedback.flashSuccess(statusItem: statusItem)
    }

    private func tick() async {
        guard isEnabled, !inFlight else { return }
        let point = NSEvent.mouseLocation
        if hypot(point.x - lastPoint.x, point.y - lastPoint.y) < 3, currentHit != nil {
            return
        }
        lastPoint = point
        inFlight = true
        defer { inFlight = false }

        let screen = NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) } ?? NSScreen.main
        guard let screen else { return }
        let region = SelectionGeometry.tipRegion(around: point, side: 220, within: screen.frame)

        do {
            let image = try await cropper.capture(rectInAppKit: region)
            let hit = try await findText(under: point, in: image, region: region)
            currentHit = hit
            outlinedText = hit?.text
            if let hit {
                outlineWindow?.show(rect: hit.rect)
            } else {
                outlineWindow?.orderOut(nil)
            }
        } catch {
            currentHit = nil
            outlineWindow?.orderOut(nil)
        }
    }

    private func findText(under point: CGPoint, in image: CGImage, region: CGRect) async throws -> Hit? {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }

                // Map pointer into normalized image coords (Vision: bottom-left).
                let relX = (point.x - region.minX) / region.width
                let relYFromTop = (point.y - region.minY) / region.height
                let visionX = relX
                let visionY = 1 - relYFromTop

                var best: Hit?
                var bestArea = CGFloat.greatestFiniteMagnitude

                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    let box = observation.boundingBox
                    guard box.contains(CGPoint(x: visionX, y: visionY)) else { continue }

                    // Convert Vision box → AppKit global rect.
                    let appKitRect = CGRect(
                        x: region.minX + box.minX * region.width,
                        y: region.minY + (1 - box.maxY) * region.height,
                        width: box.width * region.width,
                        height: box.height * region.height
                    )
                    let area = appKitRect.width * appKitRect.height
                    if area < bestArea {
                        bestArea = area
                        best = Hit(text: candidate.string, rect: appKitRect)
                    }
                }
                continuation.resume(returning: best)
            }
            request.recognitionLevel = .fast
            request.usesLanguageCorrection = false
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

private final class OutlineWindow: NSWindow {
    convenience init() {
        self.init(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hasShadow = false
        contentView = OutlineView(frame: .zero)
    }

    func show(rect: CGRect) {
        setFrame(rect.insetBy(dx: -2, dy: -2), display: true)
        (contentView as? OutlineView)?.needsDisplay = true
        orderFrontRegardless()
    }
}

private final class OutlineView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        Brand.mintNS.setStroke()
        let path = NSBezierPath(rect: bounds.insetBy(dx: 1, dy: 1))
        path.lineWidth = 2
        path.stroke()
    }
}
