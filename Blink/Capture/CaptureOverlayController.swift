import AppKit
import SwiftUI

/// Full-screen dim + system crosshair cursor + drag-select overlay across all displays.
@MainActor
final class CaptureOverlayController: NSObject {
    private var windows: [CaptureOverlayWindow] = []
    private var startPoint: CGPoint?
    private var currentRect: CGRect?
    private var escapeMonitor: Any?
    private var didPushCrosshair = false
    private var isPresented = false
    var onComplete: ((CGRect?) -> Void)?

    func present() {
        dismissOverlay()
        for screen in NSScreen.screens {
            let window = CaptureOverlayWindow(screen: screen)
            window.overlayDelegate = self
            window.orderFrontRegardless()
            windows.append(window)
        }
        isPresented = true
        pushSystemCrosshair()
        installEscapeMonitor()
        NSApp.activate(ignoringOtherApps: true)
        windows.first?.makeKeyAndOrderFront(nil)
    }

    /// Tear down UI without invoking `onComplete` (used when re-presenting).
    func dismissOverlay() {
        guard isPresented || !windows.isEmpty || didPushCrosshair || escapeMonitor != nil else { return }
        teardownUI()
        startPoint = nil
        currentRect = nil
    }

    fileprivate func beginDrag(at point: CGPoint) {
        startPoint = point
        currentRect = nil
        windows.forEach { $0.selectionRect = nil }
    }

    fileprivate func updateDrag(to point: CGPoint) {
        guard let start = startPoint else { return }
        currentRect = SelectionGeometry.rect(from: start, to: point, minimumSide: 1)
        windows.forEach { $0.selectionRect = currentRect }
    }

    fileprivate func endDrag(at point: CGPoint) {
        guard isPresented else { return }
        updateDrag(to: point)
        let finalized = currentRect.flatMap {
            SelectionGeometry.rect(
                from: CGPoint(x: $0.minX, y: $0.minY),
                to: CGPoint(x: $0.maxX, y: $0.maxY),
                minimumSide: 4
            )
        }
        teardownUI()
        startPoint = nil
        currentRect = nil
        onComplete?(finalized)
    }

    fileprivate func cancel() {
        guard isPresented else { return }
        teardownUI()
        startPoint = nil
        currentRect = nil
        onComplete?(nil)
    }

    private func teardownUI() {
        isPresented = false
        removeEscapeMonitor()
        popSystemCrosshair()
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }

    private func pushSystemCrosshair() {
        guard !didPushCrosshair else { return }
        NSCursor.crosshair.push()
        didPushCrosshair = true
        windows.forEach { $0.invalidateCursorRects(for: $0.contentView ?? NSView()) }
    }

    private func popSystemCrosshair() {
        guard didPushCrosshair else { return }
        NSCursor.pop()
        didPushCrosshair = false
    }

    private func installEscapeMonitor() {
        removeEscapeMonitor()
        // Local monitor so Esc works before/during drag even if a view loses first responder.
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            Task { @MainActor in
                self?.cancel()
            }
            return nil
        }
    }

    private func removeEscapeMonitor() {
        if let escapeMonitor {
            NSEvent.removeMonitor(escapeMonitor)
            self.escapeMonitor = nil
        }
    }
}

private protocol CaptureOverlayWindowDelegate: AnyObject {
    func beginDrag(at point: CGPoint)
    func updateDrag(to point: CGPoint)
    func endDrag(at point: CGPoint)
    func cancel()
}

extension CaptureOverlayController: CaptureOverlayWindowDelegate {}

private final class CaptureOverlayWindow: NSWindow {
    weak var overlayDelegate: CaptureOverlayWindowDelegate?
    var selectionRect: CGRect? {
        didSet { contentView?.needsDisplay = true }
    }

    convenience init(screen: NSScreen) {
        self.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        isOpaque = false
        backgroundColor = .clear
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        ignoresMouseEvents = false
        hasShadow = false
        acceptsMouseMovedEvents = true
        contentView = CaptureOverlayView(frame: screen.frame)
        (contentView as? CaptureOverlayView)?.owner = self
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private final class CaptureOverlayView: NSView {
    weak var owner: CaptureOverlayWindow?

    override func viewDidMoveToWindow() {
        window?.makeKey()
        window?.makeFirstResponder(self)
        NSCursor.crosshair.set()
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.crosshair.set()
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.35).setFill()
        bounds.fill()

        guard let window = owner else { return }
        let localSelection: CGRect? = {
            guard let global = window.selectionRect else { return nil }
            let screenFrame = window.screen?.frame ?? window.frame
            let clipped = global.intersection(screenFrame)
            guard !clipped.isNull, clipped.width > 0, clipped.height > 0 else { return nil }
            let originInWindow = window.convertPoint(fromScreen: clipped.origin)
            return CGRect(origin: originInWindow, size: clipped.size)
        }()

        if let selection = localSelection, selection.width > 0, selection.height > 0 {
            NSGraphicsContext.current?.compositingOperation = .clear
            selection.fill()
            NSGraphicsContext.current?.compositingOperation = .sourceOver

            // Quiet selection stroke — mint only as a light accent, not a custom pointer.
            Brand.mintNS.withAlphaComponent(0.95).setStroke()
            let path = NSBezierPath(rect: selection.insetBy(dx: 0.5, dy: 0.5))
            path.lineWidth = 1.5
            path.stroke()
        }
    }

    override func mouseEntered(with event: NSEvent) {
        NSCursor.crosshair.set()
    }

    override func mouseMoved(with event: NSEvent) {
        NSCursor.crosshair.set()
    }

    override func mouseDown(with event: NSEvent) {
        NSCursor.crosshair.set()
        owner?.overlayDelegate?.beginDrag(at: NSEvent.mouseLocation)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        NSCursor.crosshair.set()
        owner?.overlayDelegate?.updateDrag(to: NSEvent.mouseLocation)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        owner?.overlayDelegate?.endDrag(at: NSEvent.mouseLocation)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            owner?.overlayDelegate?.cancel()
        }
    }

    override var acceptsFirstResponder: Bool { true }
}
