//
//  magnetifyTests.swift
//  magnetifyTests
//
//  Created by Magnetify Contributors on 28.03.2026.
//

import XCTest
import Carbon
@testable import magnetify

// MARK: - SnapCalculator Tests

final class SnapCalculatorTests: XCTestCase {

    private let area = CGRect(x: 0, y: 0, width: 1000, height: 800)
    private let calculator = SnapCalculator(gap: 0)

    // MARK: Halves

    func testLeftHalf() {
        let frame = calculator.frame(for: .leftHalf, in: area)
        XCTAssertEqual(frame, CGRect(x: 0, y: 0, width: 500, height: 800))
    }

    func testRightHalf() {
        let frame = calculator.frame(for: .rightHalf, in: area)
        XCTAssertEqual(frame, CGRect(x: 500, y: 0, width: 500, height: 800))
    }

    func testTopHalf() {
        // macOS coordinate system: y=0 is bottom, top half starts at midpoint
        let frame = calculator.frame(for: .topHalf, in: area)
        XCTAssertEqual(frame, CGRect(x: 0, y: 400, width: 1000, height: 400))
    }

    func testBottomHalf() {
        let frame = calculator.frame(for: .bottomHalf, in: area)
        XCTAssertEqual(frame, CGRect(x: 0, y: 0, width: 1000, height: 400))
    }

    func testHalvesCoverFullWidth() {
        let left = calculator.frame(for: .leftHalf, in: area)
        let right = calculator.frame(for: .rightHalf, in: area)
        XCTAssertEqual(left.width + right.width, area.width)
    }

    func testHalvesCoverFullHeight() {
        let top = calculator.frame(for: .topHalf, in: area)
        let bottom = calculator.frame(for: .bottomHalf, in: area)
        XCTAssertEqual(top.height + bottom.height, area.height)
    }

    // MARK: Quarters

    func testTopLeft() {
        let frame = calculator.frame(for: .topLeft, in: area)
        XCTAssertEqual(frame, CGRect(x: 0, y: 400, width: 500, height: 400))
    }

    func testTopRight() {
        let frame = calculator.frame(for: .topRight, in: area)
        XCTAssertEqual(frame, CGRect(x: 500, y: 400, width: 500, height: 400))
    }

    func testBottomLeft() {
        let frame = calculator.frame(for: .bottomLeft, in: area)
        XCTAssertEqual(frame, CGRect(x: 0, y: 0, width: 500, height: 400))
    }

    func testBottomRight() {
        let frame = calculator.frame(for: .bottomRight, in: area)
        XCTAssertEqual(frame, CGRect(x: 500, y: 0, width: 500, height: 400))
    }

    func testAllQuartersAreEqualSize() {
        let positions: [SnapPosition] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        let frames = positions.map { calculator.frame(for: $0, in: area) }
        let firstSize = frames[0].size
        for frame in frames {
            XCTAssertEqual(frame.width, firstSize.width, accuracy: 0.01)
            XCTAssertEqual(frame.height, firstSize.height, accuracy: 0.01)
        }
    }

    func testQuartersEachAre25PercentOfArea() {
        let frame = calculator.frame(for: .topLeft, in: area)
        let quarterArea = area.width * area.height / 4
        XCTAssertEqual(frame.width * frame.height, quarterArea, accuracy: 0.01)
    }

    // MARK: Thirds

    func testLeftThird() {
        let frame = calculator.frame(for: .leftThird, in: area)
        XCTAssertEqual(frame.origin.x, 0)
        XCTAssertEqual(frame.width, 1000.0 / 3.0, accuracy: 0.01)
        XCTAssertEqual(frame.height, 800)
    }

    func testCenterThird() {
        let frame = calculator.frame(for: .centerThird, in: area)
        let thirdW = 1000.0 / 3.0
        XCTAssertEqual(frame.origin.x, thirdW, accuracy: 0.01)
        XCTAssertEqual(frame.width, thirdW, accuracy: 0.01)
        XCTAssertEqual(frame.height, 800)
    }

    func testRightThird() {
        let frame = calculator.frame(for: .rightThird, in: area)
        let thirdW = 1000.0 / 3.0
        XCTAssertEqual(frame.origin.x, thirdW * 2, accuracy: 0.01)
        XCTAssertEqual(frame.width, thirdW, accuracy: 0.01)
        XCTAssertEqual(frame.height, 800)
    }

    func testThirdsCoverFullWidth() {
        let left = calculator.frame(for: .leftThird, in: area)
        let center = calculator.frame(for: .centerThird, in: area)
        let right = calculator.frame(for: .rightThird, in: area)
        let totalWidth = left.width + center.width + right.width
        XCTAssertEqual(totalWidth, area.width, accuracy: 0.01)
    }

    // MARK: Two-Thirds

    func testLeftTwoThirds() {
        let frame = calculator.frame(for: .leftTwoThirds, in: area)
        let thirdW = 1000.0 / 3.0
        XCTAssertEqual(frame.origin.x, 0)
        XCTAssertEqual(frame.width, thirdW * 2, accuracy: 0.01)
        XCTAssertEqual(frame.height, 800)
    }

    func testRightTwoThirds() {
        let frame = calculator.frame(for: .rightTwoThirds, in: area)
        let thirdW = 1000.0 / 3.0
        XCTAssertEqual(frame.origin.x, thirdW, accuracy: 0.01)
        XCTAssertEqual(frame.width, thirdW * 2, accuracy: 0.01)
        XCTAssertEqual(frame.height, 800)
    }

    // MARK: Fullscreen and Center

    func testFullscreen() {
        let frame = calculator.frame(for: .fullscreen, in: area)
        XCTAssertEqual(frame, CGRect(x: 0, y: 0, width: 1000, height: 800))
    }

    func testCenter() {
        let frame = calculator.frame(for: .center, in: area)
        let expectedW = 1000.0 * 0.7
        let expectedH = 800.0 * 0.7
        XCTAssertEqual(frame.width, expectedW, accuracy: 0.01)
        XCTAssertEqual(frame.height, expectedH, accuracy: 0.01)
        // Verify it is centered
        XCTAssertEqual(frame.midX, area.midX, accuracy: 0.01)
        XCTAssertEqual(frame.midY, area.midY, accuracy: 0.01)
    }

    func testCenterIs70PercentOfArea() {
        let frame = calculator.frame(for: .center, in: area)
        XCTAssertEqual(frame.width / area.width, 0.7, accuracy: 0.01)
        XCTAssertEqual(frame.height / area.height, 0.7, accuracy: 0.01)
    }

    // MARK: Gap Tests

    func testWithGapLeftHalf() {
        let calc = SnapCalculator(gap: 10)
        let frame = calc.frame(for: .leftHalf, in: area)
        // x = 0 + 10, y = 0 + 10, w = (1000-20-10)/2 = 485, h = 800-20 = 780
        XCTAssertEqual(frame.origin.x, 10)
        XCTAssertEqual(frame.origin.y, 10)
        XCTAssertEqual(frame.width, 485)
        XCTAssertEqual(frame.height, 780)
    }

    func testWithGapRightHalf() {
        let calc = SnapCalculator(gap: 10)
        let frame = calc.frame(for: .rightHalf, in: area)
        // x = 10 + 485 + 10 = 505, width = 485
        XCTAssertEqual(frame.origin.x, 505)
        XCTAssertEqual(frame.width, 485)
    }

    func testGapReducesWindowSize() {
        let noGap = SnapCalculator(gap: 0)
        let withGap = SnapCalculator(gap: 10)
        let frameNoGap = noGap.frame(for: .fullscreen, in: area)
        let frameWithGap = withGap.frame(for: .fullscreen, in: area)
        XCTAssertGreaterThan(frameNoGap.width, frameWithGap.width)
        XCTAssertGreaterThan(frameNoGap.height, frameWithGap.height)
    }

    func testGapFullscreenInsets() {
        let calc = SnapCalculator(gap: 10)
        let frame = calc.frame(for: .fullscreen, in: area)
        // With gap=10: x=10, y=10, w=980, h=780
        XCTAssertEqual(frame.origin.x, 10)
        XCTAssertEqual(frame.origin.y, 10)
        XCTAssertEqual(frame.width, 980)
        XCTAssertEqual(frame.height, 780)
    }

    func testGapThirdsHaveSpacingBetween() {
        let calc = SnapCalculator(gap: 10)
        let left = calc.frame(for: .leftThird, in: area)
        let center = calc.frame(for: .centerThird, in: area)
        let right = calc.frame(for: .rightThird, in: area)
        // There should be a gap between left.maxX and center.minX
        XCTAssertEqual(center.minX - left.maxX, 10, accuracy: 0.01)
        XCTAssertEqual(right.minX - center.maxX, 10, accuracy: 0.01)
    }

    func testDefaultGapIsZero() {
        let calc = SnapCalculator()
        XCTAssertEqual(calc.gap, 0)
    }

    func testAllPositionsReturnNonEmptyFrame() {
        for position in SnapPosition.allCases {
            let frame = calculator.frame(for: position, in: area)
            XCTAssertGreaterThan(frame.width, 0, "Width should be positive for \(position)")
            XCTAssertGreaterThan(frame.height, 0, "Height should be positive for \(position)")
        }
    }

    func testAllPositionsStayWithinArea() {
        for position in SnapPosition.allCases {
            let frame = calculator.frame(for: position, in: area)
            XCTAssertGreaterThanOrEqual(frame.minX, area.minX, "\(position) exceeds left boundary")
            XCTAssertGreaterThanOrEqual(frame.minY, area.minY, "\(position) exceeds bottom boundary")
            XCTAssertLessThanOrEqual(frame.maxX, area.maxX + 0.01, "\(position) exceeds right boundary")
            XCTAssertLessThanOrEqual(frame.maxY, area.maxY + 0.01, "\(position) exceeds top boundary")
        }
    }

    func testWithOffsetArea() {
        let offsetArea = CGRect(x: 100, y: 200, width: 1000, height: 800)
        let frame = calculator.frame(for: .leftHalf, in: offsetArea)
        XCTAssertEqual(frame.origin.x, 100)
        XCTAssertEqual(frame.origin.y, 200)
        XCTAssertEqual(frame.width, 500)
    }
}

// MARK: - SnapPosition Tests

final class SnapPositionTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(SnapPosition.allCases.count, 18)
    }

    func testAllPositionsHaveDisplayName() {
        for position in SnapPosition.allCases {
            XCTAssertFalse(position.displayName.isEmpty, "\(position) has empty displayName")
        }
    }

    func testAllPositionsHaveIcon() {
        for position in SnapPosition.allCases {
            XCTAssertFalse(position.icon.isEmpty, "\(position) has empty icon")
        }
    }

    func testHalvesCategoryHasFourPositions() {
        let halves = SnapCategory.halves.positions
        XCTAssertEqual(halves.count, 4)
        XCTAssertTrue(halves.contains(.leftHalf))
        XCTAssertTrue(halves.contains(.rightHalf))
        XCTAssertTrue(halves.contains(.topHalf))
        XCTAssertTrue(halves.contains(.bottomHalf))
    }

    func testQuartersCategoryHasFourPositions() {
        let quarters = SnapCategory.quarters.positions
        XCTAssertEqual(quarters.count, 4)
        XCTAssertTrue(quarters.contains(.topLeft))
        XCTAssertTrue(quarters.contains(.topRight))
        XCTAssertTrue(quarters.contains(.bottomLeft))
        XCTAssertTrue(quarters.contains(.bottomRight))
    }

    func testThirdsCategoryHasThreePositions() {
        let thirds = SnapCategory.thirds.positions
        XCTAssertEqual(thirds.count, 3)
        XCTAssertTrue(thirds.contains(.leftThird))
        XCTAssertTrue(thirds.contains(.centerThird))
        XCTAssertTrue(thirds.contains(.rightThird))
    }

    func testTwoThirdsCategoryHasTwoPositions() {
        let twoThirds = SnapCategory.twoThirds.positions
        XCTAssertEqual(twoThirds.count, 2)
        XCTAssertTrue(twoThirds.contains(.leftTwoThirds))
        XCTAssertTrue(twoThirds.contains(.rightTwoThirds))
    }

    func testOtherCategoryHasThreePositions() {
        let other = SnapCategory.other.positions
        XCTAssertEqual(other.count, 3)
        XCTAssertTrue(other.contains(.fullscreen))
        XCTAssertTrue(other.contains(.center))
        XCTAssertTrue(other.contains(.restore))
    }

    func testAllPositionsBelongToExactlyOneCategory() {
        var total = 0
        for category in SnapCategory.allCases {
            total += category.positions.count
        }
        XCTAssertEqual(total, SnapPosition.allCases.count)
    }

    func testCodableRoundTrip() throws {
        for position in SnapPosition.allCases {
            let data = try JSONEncoder().encode(position)
            let decoded = try JSONDecoder().decode(SnapPosition.self, from: data)
            XCTAssertEqual(decoded, position, "Round-trip failed for \(position)")
        }
    }

    func testRawValueUniqueness() {
        let rawValues = SnapPosition.allCases.map { $0.rawValue }
        XCTAssertEqual(Set(rawValues).count, rawValues.count, "Raw values should be unique")
    }

    func testIdentifiableIdMatchesRawValue() {
        for position in SnapPosition.allCases {
            XCTAssertEqual(position.id, position.rawValue)
        }
    }

    func testMonitorCategoryHasTwoPositions() {
        let monitor = SnapCategory.monitor.positions
        XCTAssertEqual(monitor.count, 2)
        XCTAssertTrue(monitor.contains(.moveToNextScreen))
        XCTAssertTrue(monitor.contains(.moveToPreviousScreen))
    }

    func testSnapCategoryAllCasesCount() {
        XCTAssertEqual(SnapCategory.allCases.count, 6)
    }

    func testSnapCategoryDisplayNamesNotEmpty() {
        for category in SnapCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty, "\(category) has empty displayName")
        }
    }
}

// MARK: - DefaultShortcuts Tests

final class DefaultShortcutsTests: XCTestCase {

    func testAllPositionsCovered() {
        let shortcuts = DefaultShortcuts.all()
        let positions = Set(shortcuts.map { $0.position })
        for position in SnapPosition.allCases {
            XCTAssertTrue(positions.contains(position), "Missing shortcut for \(position)")
        }
    }

    func testShortcutCountMatchesPositionCount() {
        let shortcuts = DefaultShortcuts.all()
        XCTAssertEqual(shortcuts.count, SnapPosition.allCases.count)
    }

    func testNoDuplicateKeyCombinations() {
        let shortcuts = DefaultShortcuts.all()
        var seen = Set<String>()
        for shortcut in shortcuts {
            let key = "\(shortcut.keyCode)-\(shortcut.modifiers)"
            XCTAssertFalse(seen.contains(key), "Duplicate key combination: \(key)")
            seen.insert(key)
        }
    }

    func testAllDefaultShortcutsAreEnabled() {
        let shortcuts = DefaultShortcuts.all()
        for shortcut in shortcuts {
            XCTAssertTrue(shortcut.isEnabled, "Shortcut for \(shortcut.position) should be enabled by default")
        }
    }

    func testAllShortcutsUseControlOptionModifiers() {
        let shortcuts = DefaultShortcuts.all()
        let controlOption = UInt32(controlKey) | UInt32(optionKey)
        let controlOptionCmd = UInt32(controlKey) | UInt32(optionKey) | UInt32(cmdKey)
        let monitorPositions: Set<SnapPosition> = [.moveToNextScreen, .moveToPreviousScreen]
        for shortcut in shortcuts {
            if monitorPositions.contains(shortcut.position) {
                XCTAssertEqual(shortcut.modifiers, controlOptionCmd,
                               "Monitor shortcut for \(shortcut.position) should use Control+Option+Cmd modifiers")
            } else {
                XCTAssertEqual(shortcut.modifiers, controlOption,
                               "Shortcut for \(shortcut.position) should use Control+Option modifiers")
            }
        }
    }

    func testNoDuplicatePositions() {
        let shortcuts = DefaultShortcuts.all()
        let positions = shortcuts.map { $0.position }
        XCTAssertEqual(Set(positions).count, positions.count, "Each position should appear exactly once")
    }
}

// MARK: - ShortcutBinding Tests

final class ShortcutBindingTests: XCTestCase {

    func testCodableRoundTrip() throws {
        let binding = ShortcutBinding(position: .leftHalf, keyCode: 0x7B, modifiers: UInt32(controlKey) | UInt32(optionKey))
        let data = try JSONEncoder().encode(binding)
        let decoded = try JSONDecoder().decode(ShortcutBinding.self, from: data)
        XCTAssertEqual(decoded.position, binding.position)
        XCTAssertEqual(decoded.keyCode, binding.keyCode)
        XCTAssertEqual(decoded.modifiers, binding.modifiers)
        XCTAssertEqual(decoded.isEnabled, binding.isEnabled)
        XCTAssertEqual(decoded.id, binding.id)
    }

    func testDisplayStringContainsControlSymbol() {
        let binding = ShortcutBinding(position: .leftHalf, keyCode: 0x7B, modifiers: UInt32(controlKey))
        XCTAssertTrue(binding.displayString.contains("⌃"), "Display string should contain ⌃ for control modifier")
    }

    func testDisplayStringContainsOptionSymbol() {
        let binding = ShortcutBinding(position: .leftHalf, keyCode: 0x7B, modifiers: UInt32(optionKey))
        XCTAssertTrue(binding.displayString.contains("⌥"), "Display string should contain ⌥ for option modifier")
    }

    func testDisplayStringContainsCmdSymbol() {
        let binding = ShortcutBinding(position: .leftHalf, keyCode: 0x7B, modifiers: UInt32(cmdKey))
        XCTAssertTrue(binding.displayString.contains("⌘"), "Display string should contain ⌘ for cmd modifier")
    }

    func testDisplayStringContainsShiftSymbol() {
        let binding = ShortcutBinding(position: .leftHalf, keyCode: 0x7B, modifiers: UInt32(shiftKey))
        XCTAssertTrue(binding.displayString.contains("⇧"), "Display string should contain ⇧ for shift modifier")
    }

    func testDisplayStringContainsKeyName() {
        let binding = ShortcutBinding(position: .leftHalf, keyCode: 0x7B, modifiers: UInt32(controlKey) | UInt32(optionKey))
        // 0x7B maps to "←"
        XCTAssertTrue(binding.displayString.contains("←"), "Display string should contain key name")
    }

    func testDisplayStringWithMultipleModifiers() {
        let binding = ShortcutBinding(position: .leftHalf, keyCode: 0x7B,
                                      modifiers: UInt32(controlKey) | UInt32(optionKey))
        let display = binding.displayString
        XCTAssertTrue(display.contains("⌃"), "Should contain control symbol")
        XCTAssertTrue(display.contains("⌥"), "Should contain option symbol")
        XCTAssertTrue(display.contains("←"), "Should contain arrow key name")
    }

    func testDisplayStringModifierOrder() {
        // Modifiers should appear in order: ⌃ ⌥ ⇧ ⌘
        let allMods = UInt32(controlKey) | UInt32(optionKey) | UInt32(shiftKey) | UInt32(cmdKey)
        let binding = ShortcutBinding(position: .fullscreen, keyCode: 0x00, modifiers: allMods)
        let display = binding.displayString
        if let controlIdx = display.firstIndex(of: "⌃"),
           let optionIdx = display.firstIndex(of: "⌥"),
           let shiftIdx = display.firstIndex(of: "⇧"),
           let cmdIdx = display.firstIndex(of: "⌘") {
            XCTAssertLessThan(controlIdx, optionIdx)
            XCTAssertLessThan(optionIdx, shiftIdx)
            XCTAssertLessThan(shiftIdx, cmdIdx)
        } else {
            XCTFail("Display string missing expected modifier symbols")
        }
    }

    func testDefaultIsEnabled() {
        let binding = ShortcutBinding(position: .center, keyCode: 0x08, modifiers: 0)
        XCTAssertTrue(binding.isEnabled)
    }

    func testEquatable() {
        let binding = ShortcutBinding(position: .leftHalf, keyCode: 0x7B, modifiers: UInt32(controlKey))
        XCTAssertEqual(binding, binding)
    }

    func testUniqueIDs() {
        let binding1 = ShortcutBinding(position: .leftHalf, keyCode: 0x7B, modifiers: 0)
        let binding2 = ShortcutBinding(position: .leftHalf, keyCode: 0x7B, modifiers: 0)
        XCTAssertNotEqual(binding1.id, binding2.id, "Each binding should get a unique ID")
    }
}

// MARK: - KeyCodeMapping Tests

final class KeyCodeMappingTests: XCTestCase {

    func testArrowKeys() {
        XCTAssertEqual(KeyCodeMapping.name(for: 0x7B), "←")
        XCTAssertEqual(KeyCodeMapping.name(for: 0x7C), "→")
        XCTAssertEqual(KeyCodeMapping.name(for: 0x7D), "↓")
        XCTAssertEqual(KeyCodeMapping.name(for: 0x7E), "↑")
    }

    func testLetterKeys() {
        XCTAssertEqual(KeyCodeMapping.name(for: 0x00), "A")
        XCTAssertEqual(KeyCodeMapping.name(for: 0x01), "S")
        XCTAssertEqual(KeyCodeMapping.name(for: 0x02), "D")
        XCTAssertEqual(KeyCodeMapping.name(for: 0x03), "F")
    }

    func testSpecialKeys() {
        XCTAssertEqual(KeyCodeMapping.name(for: 0x24), "↩")
        XCTAssertEqual(KeyCodeMapping.name(for: 0x31), "Space")
        XCTAssertEqual(KeyCodeMapping.name(for: 0x33), "⌫")
        XCTAssertEqual(KeyCodeMapping.name(for: 0x35), "⎋")
    }

    func testUnknownKeyCodeReturnsNil() {
        XCTAssertNil(KeyCodeMapping.name(for: 0xFF))
    }
}
