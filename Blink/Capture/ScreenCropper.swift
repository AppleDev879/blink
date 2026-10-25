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

        guard let display = content.displays.first(where: { display in
            let frame = CGRect(x: display.frame.origin.x, y: display.frame.origin.y, width: CGFloat(display.width), height: CGFloat(display.height))
            // Match by intersection in CG space roughly; prefer display containing rect center.
            return frame.insetBy(dx: -1, dy: -1).contains(CGPoint(x: cgRect.midX, y: cgRect.midY))
        }) ?? content.displays.first else {
            throw ScreenCropperError.noDisplay
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        config.width = max(1, Int(appKitRect.width * scale))
        config.height = max(1, Int(appKitRect.height * scale))
        config.sourceRect = cgRect
        config.showsCursor = false
        config.pixelFormat = kCVPixelFormatType_32BGRA

        do {
            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            return image
        } catch {
            throw ScreenCropperError.captureFailed(error.localizedDescription)
        }
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
