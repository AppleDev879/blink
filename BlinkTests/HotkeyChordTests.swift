import XCTest
@testable import Blink

final class HotkeyChordTests: XCTestCase {
    func testDefaultCaptureChord() {
        let chord = HotkeyChord.captureDefault
        XCTAssertEqual(chord.keyCode, 19)
        XCTAssertTrue(chord.modifiers.contains(.command))
        XCTAssertTrue(chord.modifiers.contains(.shift))
        XCTAssertEqual(chord.displayLabel, "⇧⌘2")
    }

    func testParseCmdShift2Variants() {
        let a = HotkeyChord.parse("cmd+shift+2")
        let b = HotkeyChord.parse("⌘⇧2")
        let c = HotkeyChord.parse("command-shift-2")
        XCTAssertEqual(a, HotkeyChord.captureDefault)
        XCTAssertEqual(b, HotkeyChord.captureDefault)
        XCTAssertEqual(c, HotkeyChord.captureDefault)
    }

    func testParseRejectsBareKey() {
        XCTAssertNil(HotkeyChord.parse("2"))
        XCTAssertNil(HotkeyChord.parse(""))
    }

    func testParseOptionChord() {
        let chord = HotkeyChord.parse("option+shift+a")
        XCTAssertEqual(chord?.keyCode, 0)
        XCTAssertEqual(chord?.modifiers, [.option, .shift])
    }
}
