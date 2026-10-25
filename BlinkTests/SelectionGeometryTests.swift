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
}
