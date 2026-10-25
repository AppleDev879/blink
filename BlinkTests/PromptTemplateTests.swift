import XCTest
@testable import Blink

final class PromptTemplateTests: XCTestCase {
    func testReplacesPlaceholder() {
        let out = PromptTemplate.interpolate("Fix:\n\n{{text}}", text: "he11o")
        XCTAssertEqual(out, "Fix:\n\nhe11o")
    }

    func testReplacesEveryOccurrence() {
        let out = PromptTemplate.interpolate("{{text}} :: {{text}}", text: "x")
        XCTAssertEqual(out, "x :: x")
    }

    func testMissingPlaceholderAppendsText() {
        let out = PromptTemplate.interpolate("Clean this up:", text: "raw")
        XCTAssertEqual(out, "Clean this up:\n\nraw")
    }

    func testEmptyTemplateReturnsText() {
        XCTAssertEqual(PromptTemplate.interpolate("  ", text: "only"), "only")
    }

    func testDefaultTemplateContainsPlaceholder() {
        XCTAssertTrue(PromptTemplate.defaultTemplate.contains(PromptTemplate.textPlaceholder))
    }
}
