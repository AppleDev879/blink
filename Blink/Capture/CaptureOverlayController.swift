import AppKit
import SwiftUI

/// Full-screen dim + mint crosshairs + drag-select overlay across all displays.
@MainActor
final class CaptureOverlayController: NSObject {
    private var windows: [CaptureOverlayWindow] = []
    private var startPoint: CGPoint?
    private var currentRect: CGRect?
    private var escapeMonitor: Any?
    private var didHideCursor = false
    private var isPresented = false
    var onComplete: ((CGRect?) -> Void)?

    func present() {
        dismiss(commit: false)
        for screen in NSScreen.screens {
            let window = CaptureOverlayWindow(screen: screen)
            window.overlayDelegate = self
            window.orderFrontRegardless()
            windows.append(window)
        }
        isPresented = true
        hideSystemCursor()
        installEscapeMonitor()
        NSApp.activate(ignoringOtherApps: true)
        windows.first?.makeKeyAndOrderFront(nil)
    }

    func dismiss(commit: Bool) {
        let result = commit ? currentRect : nil
        let wasPresented = isPresented
        teardownUI()
        startPoint = nil
        currentRect = nil
        if commit, wasPresented {
            onComplete?(result)
        }
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
        currentRect = finalized
        teardownUI()
        startPoint = nil
        let rect = currentRect
        currentRect = nil
        onComplete?(rect)
    }

    fileprivate func cancel() {
        guard isPresented else { return }
        dismiss(commit: false)
        onComplete?(nil)
    }

    private func teardownUI() {
        isPresented = false
        removeEscapeMonitor()
        restoreSystemCursor()
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }

    private func hideSystemCursor() {
        guard !didHideCursor else { return }
        NSCursor.hide()
        didHideCursor = true
    }

    private func restoreSystemCursor() {
        guard didHideCursor else { return }
        NSCursor.unhide()
        didHideCursor = false
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
    }

    override func draw(_ dirtyRect: NSRect) {
        // Dim
        NSColor.black.withAlphaComponent(0.35).setFill()
        bounds.fill()

        guard let window = owner else { return }
        let localSelection: CGRect? = {
            guard let global = window.selectionRect else { return nil }
            let screenFrame = window.screen?.frame ?? window.frame
            let clipped = global.intersection(screenFrame)
            guard !clipped.isNull, clipped.width > 0, clipped.height > 0 else { return nil }
            // Convert global AppKit coords into this window's view coords.
            let originInWindow = window.convertPoint(fromScreen: clipped.origin)
            return CGRect(origin: originInWindow, size: clipped.size)
        }()

        if let selection = localSelection, selection.width > 0, selection.height > 0 {
            // Clear the selected region so the user sees the live screen.
            NSGraphicsContext.current?.compositingOperation = .clear
            selection.fill()
            NSGraphicsContext.current?.compositingOperation = .sourceOver

            Brand.mintNS.withAlphaComponent(0.95).setStroke()
            let path = NSBezierPath(rect: selection.insetBy(dx: 0.5, dy: 0.5))
            path.lineWidth = 1.5
            path.stroke()
        }

        drawCrosshairs()
    }

    private func drawCrosshairs() {
        let mouse = window?.mouseLocationOutsideOfEventStream ?? .zero
        Brand.mintNS.withAlphaComponent(0.85).setStroke()
        let path = NSBezierPath()
        path.lineWidth = 1
        let arm: CGFloat = 18
        let gap: CGFloat = 6
        // Horizontal
        path.move(to: CGPoint(x: mouse.x - arm, y: mouse.y))
        path.line(to: CGPoint(x: mouse.x - gap, y: mouse.y))
        path.move(to: CGPoint(x: mouse.x + gap, y: mouse.y))
        path.line(to: CGPoint(x: mouse.x + arm, y: mouse.y))
        // Vertical
        path.move(to: CGPoint(x: mouse.x, y: mouse.y - arm))
        path.line(to: CGPoint(x: mouse.x, y: mouse.y - gap))
        path.move(to: CGPoint(x: mouse.x, y: mouse.y + gap))
        path.line(to: CGPoint(x: mouse.x, y: mouse.y + arm))
        path.stroke()

        // Center open square
        let box: CGFloat = 8
        let square = NSRect(x: mouse.x - box / 2, y: mouse.y - box / 2, width: box, height: box)
        let squarePath = NSBezierPath(rect: square)
        squarePath.lineWidth = 1.25
        squarePath.stroke()
    }

    override func mouseMoved(with event: NSEvent) {
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        let global = NSEvent.mouseLocation
        owner?.overlayDelegate?.beginDrag(at: global)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
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
