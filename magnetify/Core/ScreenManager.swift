import Foundation
import AppKit

final class ScreenManager {

    static func screen(for window: AXUIElement) -> NSScreen? {
        guard let frame = try? WindowAccessor.getWindowFrame(window) else {
            return NSScreen.main
        }

        let windowCenter = CGPoint(
            x: frame.midX,
            y: frame.midY
        )

        return screen(containing: windowCenter) ?? NSScreen.main
    }

    static func screen(containing point: CGPoint) -> NSScreen? {
        // NSScreen uses bottom-left origin, CGWindow uses top-left
        // Convert point for comparison
        for screen in NSScreen.screens {
            if screen.frame.contains(point) {
                return screen
            }
        }
        return nil
    }

    static func nextScreen(after current: NSScreen) -> NSScreen? {
        let screens = NSScreen.screens
        guard screens.count > 1 else { return nil }

        guard let currentIndex = screens.firstIndex(of: current) else {
            return screens.first
        }

        let nextIndex = (currentIndex + 1) % screens.count
        return screens[nextIndex]
    }

    static func previousScreen(before current: NSScreen) -> NSScreen? {
        let screens = NSScreen.screens
        guard screens.count > 1 else { return nil }

        guard let currentIndex = screens.firstIndex(of: current) else {
            return screens.first
        }

        let previousIndex = (currentIndex - 1 + screens.count) % screens.count
        return screens[previousIndex]
    }
}
