import XCTest
@testable import Blink

final class OCRTextNormalizerTests: XCTestCase {
    func testCollapsesWhitespaceAndTrims() {
        let raw = "  hello   world  \n\n  next\tline  \n"
        let result = OCRTextNormalizer.normalize(raw)
        XCTAssertEqual(result, "hello world\n\nnext line")
    }

    func testDropsLeadingAndTrailingBlankLines() {
        let raw = "\n\nalpha\nbeta\n\n"
        XCTAssertEqual(OCRTextNormalizer.normalize(raw), "alpha\nbeta")
    }

    func testJoinObservationsSortsTopToBottomThenLeftToRight() {
        let items: [(text: String, confidence: Float, minY: CGFloat, minX: CGFloat)] = [
            ("right", 0.9, 0.8, 0.6),
            ("left", 0.9, 0.8, 0.1),
            ("below", 0.9, 0.2, 0.1),
            ("low-conf", 0.1, 0.9, 0.9)
        ]
        let joined = OCRTextNormalizer.joinObservations(items, minimumConfidence: 0.3)
        XCTAssertEqual(joined, "left\nright\nbelow")
    }

    func testEmptyInput() {
        XCTAssertEqual(OCRTextNormalizer.normalize(""), "")
        XCTAssertEqual(OCRTextNormalizer.normalize("   \n  "), "")
    }
}
