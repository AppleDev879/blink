import AppKit
import CoreGraphics
import Foundation
import ScreenCaptureKit

enum ScreenCropperError: Error, LocalizedError {
    case noDisplay
    case captureFailed(String)
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .noDisplay: return "No display found for that selection."
        case .captureFailed(let message): return message
        case .permissionDenied: return "Screen Recording is off. Enable it in System Settings."
        }
    }
}

/// Captures a bitmap for a global AppKit-coordinate selection rect.
final class ScreenCropper {
    /// Capture using ScreenCaptureKit when available; falls back to CGWindowList.
    func capture(rectInAppKit: CGRect) async throws -> CGImage {
        let primaryHeight = NSScreen.screens.first?.frame.height
            ?? NSScreen.main?.frame.height
            ?? 0
        let cgRect = SelectionGeometry.appKitToCGGlobal(rectInAppKit, primaryScreenHeight: primaryHeight)

        if #available(macOS 14.0, *) {
            do {
                return try await captureWithScreenCaptureKit(cgRect: cgRect, appKitRect: rectInAppKit)
            } catch {
                // Fall through to legacy path when SCK is unavailable / denied mid-flight.
            }
        }

        return try captureWithCGWindowList(cgRect: cgRect)
    }

    @available(macOS 14.0, *)
    private func captureWithScreenCaptureKit(cgRect: CGRect, appKitRect: CGRect) async throws -> CGImage {
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        } catch {
            throw ScreenCropperError.permissionDenied
        }

        let center = CGPoint(x: cgRect.midX, y: cgRect.midY)
        guard let display = content.displays.first(where: { display in
            display.frame.insetBy(dx: -1, dy: -1).contains(center)
        }) ?? content.displays.first else {
            throw ScreenCropperError.noDisplay
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        let scale = backingScaleFactor(forAppKitRect: appKitRect)
        config.width = max(1, Int(appKitRect.width * scale))
        config.height = max(1, Int(appKitRect.height * scale))
        // SCK sourceRect is display-local with origin at the display’s top-left.
        config.sourceRect = SelectionGeometry.displayLocalSourceRect(
            globalCGRect: cgRect,
            displayBounds: display.frame
        )
        config.showsCursor = false
        config.pixelFormat = kCVPixelFormatType_32BGRA

        do {
            return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        } catch {
            throw ScreenCropperError.captureFailed(error.localizedDescription)
        }
    }

    private func backingScaleFactor(forAppKitRect rect: CGRect) -> CGFloat {
        let mid = CGPoint(x: rect.midX, y: rect.midY)
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mid, $0.frame, false) }) {
            return screen.backingScaleFactor
        }
        return NSScreen.main?.backingScaleFactor ?? 2
    }

    private func captureWithCGWindowList(cgRect: CGRect) throws -> CGImage {
        let bounds = CGRect(
            x: floor(cgRect.origin.x),
            y: floor(cgRect.origin.y),
            width: max(1, ceil(cgRect.width)),
            height: max(1, ceil(cgRect.height))
        )
        guard let image = CGWindowListCreateImage(
            bounds,
            .optionOnScreenBelowWindow,
            kCGNullWindowID,
            [.boundsIgnoreFraming, .bestResolution]
        ) else {
            throw ScreenCropperError.permissionDenied
        }
        return image
    }
}
