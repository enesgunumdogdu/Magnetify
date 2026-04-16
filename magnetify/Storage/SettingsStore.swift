import Foundation
import SwiftUI
import Combine

final class SettingsStore: ObservableObject {

    static let shared = SettingsStore()

    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet { LoginItemManager.shared.setLoginItemEnabled(launchAtLogin) }
    }

    @AppStorage("showMenuBarIcon") var showMenuBarIcon: Bool = true
    @AppStorage("enableDragToSnap") var enableDragToSnap: Bool = true
    @AppStorage("enableKeyboardShortcuts") var enableKeyboardShortcuts: Bool = true
    @AppStorage("enableGreenButtonSnap") var enableGreenButtonSnap: Bool = true
    @AppStorage("snapGap") var snapGap: Double = 0
    @AppStorage("snapSensitivity") var snapSensitivity: Double = 5
    @AppStorage("animationDuration") var animationDuration: Double = 0.2
    @AppStorage("previewOpacity") var previewOpacity: Double = 0.3
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("enableWindowMemory") var enableWindowMemory: Bool = false
    @AppStorage("enableAppRules") var enableAppRules: Bool = true
    @AppStorage("previewColor") var previewColorHex: String = "007AFF"
    @AppStorage("appLanguage") var appLanguage: String = ""

    var previewColor: NSColor {
        get { NSColor(hex: previewColorHex) ?? .systemBlue }
        set { previewColorHex = newValue.hexString }
    }

    private init() {}
}

extension NSColor {
    convenience init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: 1.0
        )
    }

    var hexString: String {
        guard let rgb = usingColorSpace(.sRGB) else { return "007AFF" }
        let r = Int(rgb.redComponent * 255)
        let g = Int(rgb.greenComponent * 255)
        let b = Int(rgb.blueComponent * 255)
        return String(format: "%02X%02X%02X", r, g, b)
    }
}
