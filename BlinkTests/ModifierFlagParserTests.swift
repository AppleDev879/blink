import XCTest
@testable import Blink

final class ModifierFlagParserTests: XCTestCase {
    func testParseControlVariants() {
        XCTAssertEqual(ModifierFlagParser.parse("control"), .control)
        XCTAssertEqual(ModifierFlagParser.parse("CTRL"), .control)
        XCTAssertEqual(ModifierFlagParser.parse("⌃"), .control)
        XCTAssertEqual(ModifierFlagParser.parse(" ctl "), .control)
    }

    func testParseOptionVariants() {
        XCTAssertEqual(ModifierFlagParser.parse("option"), .option)
        XCTAssertEqual(ModifierFlagParser.parse("alt"), .option)
        XCTAssertEqual(ModifierFlagParser.parse("⌥"), .option)
    }

    func testParseShiftAndCommand() {
        XCTAssertEqual(ModifierFlagParser.parse("shift"), .shift)
        XCTAssertEqual(ModifierFlagParser.parse("⇧"), .shift)
        XCTAssertEqual(ModifierFlagParser.parse("command"), .command)
        XCTAssertEqual(ModifierFlagParser.parse("cmd"), .command)
        XCTAssertEqual(ModifierFlagParser.parse("⌘"), .command)
    }

    func testParseRejectsUnknown() {
        XCTAssertNil(ModifierFlagParser.parse(""))
        XCTAssertNil(ModifierFlagParser.parse("hyper"))
        XCTAssertNil(ModifierFlagParser.parse("2"))
    }

    func testDisplayLabelFallsBackToControl() {
        XCTAssertEqual(ModifierFlagParser.displayLabel(for: "control"), "⌃")
        XCTAssertEqual(ModifierFlagParser.displayLabel(for: "nope"), "⌃")
    }

    func testEventFlagsMatch() {
        XCTAssertEqual(ModifierFlagParser.NamedModifier.control.eventFlags, .control)
        XCTAssertEqual(ModifierFlagParser.NamedModifier.option.eventFlags, .option)
        XCTAssertEqual(ModifierFlagParser.NamedModifier.shift.eventFlags, .shift)
        XCTAssertEqual(ModifierFlagParser.NamedModifier.command.eventFlags, .command)
    }
}
