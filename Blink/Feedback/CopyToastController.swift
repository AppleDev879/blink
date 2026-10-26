import AppKit
import SwiftUI

/// Bottom-of-screen toast after a successful OCR → clipboard copy.
@MainActor
enum CopyToastController {
    private static var panel: NSPanel?
    private static var dismissWork: DispatchWorkItem?

    static func show(characterCount: Int, selectionRect: CGRect?) {
        dismiss(animated: false)

        guard let screen = screen(for: selectionRect) ?? NSScreen.main ?? NSScreen.screens.first else {
            return
        }

        let message: String
        switch characterCount {
        case 0:
            message = "Copied"
        case 1:
            message = "Copied · 1 character"
        default:
            message = "Copied · \(characterCount) characters"
        }

        let hosting = NSHostingView(rootView: CopyToastView(message: message))
        hosting.frame = NSRect(x: 0, y: 0, width: 280, height: 44)

        let panel = NSPanel(
            contentRect: hosting.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hosting
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isReleasedWhenClosed = false
        panel.ignoresMouseEvents = true

        let visible = screen.visibleFrame
        let size = hosting.fittingSize
        let width = max(size.width, 160)
        let height = max(size.height, 40)
        let x = visible.midX - width / 2
        let y = visible.minY + 28
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
        panel.alphaValue = 0
        panel.orderFrontRegardless()

        self.panel = panel

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.14
            panel.animator().alphaValue = 1
        }

        let work = DispatchWorkItem {
            dismiss(animated: true)
        }
        dismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: work)
    }

    static func dismiss(animated: Bool) {
        dismissWork?.cancel()
        dismissWork = nil
        guard let panel else { return }
        self.panel = nil
        if animated {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.18
                panel.animator().alphaValue = 0
            }, completionHandler: {
                panel.orderOut(nil)
            })
        } else {
            panel.orderOut(nil)
        }
    }

    private static func screen(for selectionRect: CGRect?) -> NSScreen? {
        guard let selectionRect else { return nil }
        let mid = CGPoint(x: selectionRect.midX, y: selectionRect.midY)
        return NSScreen.screens.first { NSMouseInRect(mid, $0.frame, false) }
    }
}

private struct CopyToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(Brand.mint)
                .frame(width: 3, height: 16)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Brand.paper)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Brand.ink.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Brand.mint.opacity(0.28), lineWidth: 1)
        )
        .fixedSize()
    }
}
