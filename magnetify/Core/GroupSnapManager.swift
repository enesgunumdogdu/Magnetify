import Foundation
import AppKit
import os

final class GroupSnapManager {

    static let shared = GroupSnapManager()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify", category: "GroupSnap")

    private init() {}

    struct WindowItem: Identifiable {
        let id: CGWindowID
        let pid: pid_t
        let appName: String
        let title: String
        let axWindow: AXUIElement
    }

    func getVisibleWindows() -> [WindowItem] {
        var items: [WindowItem] = []

        let runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && !$0.isTerminated
        }

        for app in runningApps {
            guard let name = app.localizedName else { continue }
            let appElement = AXUIElementCreateApplication(app.processIdentifier)

            var windowsRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
                  let windows = windowsRef as? [AXUIElement] else { continue }

            for (index, window) in windows.enumerated() {
                guard let frame = try? WindowAccessor.getWindowFrame(window),
                      frame.width > 50 && frame.height > 50 else { continue }

                var titleRef: CFTypeRef?
                let title: String
                if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
                   let t = titleRef as? String, !t.isEmpty {
                    title = t
                } else {
                    title = "\(name) - \(String(localized: "groupSnap.window.fallbackTitle", defaultValue: "Window")) \(index + 1)"
                }

                items.append(WindowItem(
                    id: CGWindowID(app.processIdentifier) * 1000 + CGWindowID(index),
                    pid: app.processIdentifier,
                    appName: name,
                    title: title,
                    axWindow: window
                ))
            }
        }

        return items
    }

    func snapWindows(_ windows: [WindowItem], to positions: [SnapPosition]) {
        let mouseLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main else { return }
        let calculator = SnapCalculator(gap: SettingsStore.shared.snapGap)

        for (index, window) in windows.enumerated() {
            guard index < positions.count else { break }
            let frame = calculator.frame(for: positions[index], on: screen)

            do {
                try WindowAccessor.setWindowFrame(window.axWindow, frame: frame)
            } catch {
                logger.error("Failed to snap window '\(window.title)': \(error.localizedDescription)")
            }
        }

        logger.info("Group snapped \(min(windows.count, positions.count)) windows")
    }

    // Quick layouts for common multi-window arrangements
    enum QuickLayout: String, CaseIterable {
        case twoHalves
        case threeThirds
        case fourQuarters
        case mainAndSide

        var positions: [SnapPosition] {
            switch self {
            case .twoHalves: return [.leftHalf, .rightHalf]
            case .threeThirds: return [.leftThird, .centerThird, .rightThird]
            case .fourQuarters: return [.topLeft, .topRight, .bottomLeft, .bottomRight]
            case .mainAndSide: return [.leftTwoThirds, .rightThird]
            }
        }

        var displayName: String {
            switch self {
            case .twoHalves: return String(localized: "groupSnap.layout.twoHalves", defaultValue: "Two Halves")
            case .threeThirds: return String(localized: "groupSnap.layout.threeThirds", defaultValue: "Three Thirds")
            case .fourQuarters: return String(localized: "groupSnap.layout.fourQuarters", defaultValue: "Four Quarters")
            case .mainAndSide: return String(localized: "groupSnap.layout.mainAndSide", defaultValue: "Main + Side")
            }
        }

        var icon: String {
            switch self {
            case .twoHalves: return "rectangle.split.2x1"
            case .threeThirds: return "rectangle.split.3x1"
            case .fourQuarters: return "rectangle.split.2x2"
            case .mainAndSide: return "rectangle.leadinghalf.inset.filled.arrow.leading"
            }
        }
    }
}
