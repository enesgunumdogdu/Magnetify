import Foundation
import Carbon

enum DefaultShortcuts {

    private static let controlOption = UInt32(controlKey) | UInt32(optionKey)
    private static let controlOptionCmd = UInt32(controlKey) | UInt32(optionKey) | UInt32(cmdKey)

    static func all() -> [ShortcutBinding] {
        [
            // Halves
            ShortcutBinding(position: .leftHalf, keyCode: 0x7B, modifiers: controlOption),     // ⌃⌥ ←
            ShortcutBinding(position: .rightHalf, keyCode: 0x7C, modifiers: controlOption),    // ⌃⌥ →
            ShortcutBinding(position: .topHalf, keyCode: 0x7E, modifiers: controlOption),      // ⌃⌥ ↑
            ShortcutBinding(position: .bottomHalf, keyCode: 0x7D, modifiers: controlOption),   // ⌃⌥ ↓

            // Quarters
            ShortcutBinding(position: .topLeft, keyCode: 0x20, modifiers: controlOption),      // ⌃⌥ U
            ShortcutBinding(position: .topRight, keyCode: 0x22, modifiers: controlOption),     // ⌃⌥ I
            ShortcutBinding(position: .bottomLeft, keyCode: 0x26, modifiers: controlOption),   // ⌃⌥ J
            ShortcutBinding(position: .bottomRight, keyCode: 0x28, modifiers: controlOption),  // ⌃⌥ K

            // Thirds
            ShortcutBinding(position: .leftThird, keyCode: 0x02, modifiers: controlOption),    // ⌃⌥ D
            ShortcutBinding(position: .centerThird, keyCode: 0x03, modifiers: controlOption),  // ⌃⌥ F
            ShortcutBinding(position: .rightThird, keyCode: 0x05, modifiers: controlOption),   // ⌃⌥ G

            // Two-thirds
            ShortcutBinding(position: .leftTwoThirds, keyCode: 0x0E, modifiers: controlOption),  // ⌃⌥ E
            ShortcutBinding(position: .rightTwoThirds, keyCode: 0x11, modifiers: controlOption), // ⌃⌥ T

            // Monitor
            ShortcutBinding(position: .moveToNextScreen, keyCode: 0x7C, modifiers: controlOptionCmd),     // ⌃⌥⌘ →
            ShortcutBinding(position: .moveToPreviousScreen, keyCode: 0x7B, modifiers: controlOptionCmd), // ⌃⌥⌘ ←

            // Other
            ShortcutBinding(position: .fullscreen, keyCode: 0x24, modifiers: controlOption),   // ⌃⌥ Return
            ShortcutBinding(position: .center, keyCode: 0x08, modifiers: controlOption),       // ⌃⌥ C
            ShortcutBinding(position: .restore, keyCode: 0x33, modifiers: controlOption),     // ⌃⌥ Delete
        ]
    }
}
