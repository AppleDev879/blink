import CoreGraphics
import Foundation

/// Pure geometry for drag-selection rectangles across displays.
enum SelectionGeometry {
    /// Build a normalized CGRect from drag start/end in the same coordinate space.
    /// Returns `nil` when the area is below `minimumSide` (too small to OCR usefully).
    static func rect(from start: CGPoint, to end: CGPoint, minimumSide: CGFloat = 4) -> CGRect? {
        let x = min(start.x, end.x)
        let y = min(start.y, end.y)
        let w = abs(end.x - start.x)
        let h = abs(end.y - start.y)
        guard w >= minimumSide, h >= minimumSide else { return nil }
        return CGRect(x: x, y: y, width: w, height: h)
    }

    /// Convert a rect from AppKit top-left screen coords into CoreGraphics bottom-left global coords.
    static func appKitToCGGlobal(_ rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: primaryScreenHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    /// Clamp a rect to the union of available display bounds (same coordinate space as `rect`).
    static func clamp(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        let intersection = rect.intersection(bounds)
        return intersection.isNull ? .zero : intersection
    }

    /// Expand a point into a square capture region centered on the cursor tip.
    static func tipRegion(around point: CGPoint, side: CGFloat, within bounds: CGRect) -> CGRect {
        let half = side / 2
        let raw = CGRect(x: point.x - half, y: point.y - half, width: side, height: side)
        return clamp(raw, to: bounds)
    }
}
