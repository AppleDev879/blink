import XCTest
@testable import Blink

final class SelectionGeometryTests: XCTestCase {
    func testRectFromDragNormalizes() {
        let rect = SelectionGeometry.rect(from: CGPoint(x: 100, y: 200), to: CGPoint(x: 40, y: 50))
        XCTAssertEqual(rect, CGRect(x: 40, y: 50, width: 60, height: 150))
    }

    func testRejectsTinySelection() {
        XCTAssertNil(SelectionGeometry.rect(from: .zero, to: CGPoint(x: 2, y: 2), minimumSide: 4))
    }

    func testAppKitToCGGlobalFlipsY() {
        let appKit = CGRect(x: 10, y: 20, width: 100, height: 40)
        let cg = SelectionGeometry.appKitToCGGlobal(appKit, primaryScreenHeight: 800)
        // CG y = 800 - 20 - 40 = 740
        XCTAssertEqual(cg, CGRect(x: 10, y: 740, width: 100, height: 40))
    }

    func testClampToBounds() {
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        let clamped = SelectionGeometry.clamp(CGRect(x: -10, y: 50, width: 40, height: 40), to: bounds)
        XCTAssertEqual(clamped, CGRect(x: 0, y: 50, width: 30, height: 40))
    }

    func testDisplayLocalSourceRectFlipsYWithinDisplay() {
        // Secondary display to the right of a 1920-wide primary.
        let display = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let global = CGRect(x: 2000, y: 100, width: 100, height: 50)
        let local = SelectionGeometry.displayLocalSourceRect(globalCGRect: global, displayBounds: display)
        // x: 2000-1920=80; y from top: 1080 - 100 - 50 = 930
        XCTAssertEqual(local, CGRect(x: 80, y: 930, width: 100, height: 50))
    }

    func testDisplayLocalSourceRectPrimaryOrigin() {
        let display = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let global = CGRect(x: 10, y: 20, width: 40, height: 30)
        let local = SelectionGeometry.displayLocalSourceRect(globalCGRect: global, displayBounds: display)
        XCTAssertEqual(local, CGRect(x: 10, y: 850, width: 40, height: 30))
    }
}
