import Foundation
import AppKit
import os

final class WindowController {

    var calculator: SnapCalculator
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify", category: "WindowController")

    init(calculator: SnapCalculator) {
        self.calculator = calculator
        self.previousStates = Self.loadPreviousStates(logger: logger)
    }

    private func savePreviousStates() {
        do {
            let data = try JSONEncoder().encode(previousStates)
            UserDefaults.standard.set(data, forKey: Self.restoreStatesKey)
        } catch {
            logger.error("Failed to save restore states: \(error.localizedDescription)")
        }
    }

    private static func loadPreviousStates(logger: Logger) -> [WindowKey: WindowState] {
        guard let data = UserDefaults.standard.data(forKey: restoreStatesKey) else { return [:] }
        do {
            return try JSONDecoder().decode([WindowKey: WindowState].self, from: data)
        } catch {
            logger.error("Failed to load restore states: \(error.localizedDescription)")
            return [:]
        }
    }

    struct WindowState: Codable {
        let frame: CGRect
        let screenFrame: CGRect

        init(frame: CGRect, screen: NSScreen) {
            self.frame = frame
            self.screenFrame = screen.frame
        }

        /// Resolve the saved screen frame back to an active NSScreen, falling back to the main screen.
        var screen: NSScreen {
            NSScreen.screens.first { $0.frame == screenFrame } ?? NSScreen.main ?? NSScreen.screens[0]
        }
    }

    /// Composite key combining PID and window title to uniquely identify windows within the same app.
    private struct WindowKey: Hashable, Codable {
        let pid: pid_t
        let title: String
    }

    private static let restoreStatesKey = "WindowController.previousStates"

    private var previousStates: [WindowKey: WindowState] = [:] {
        didSet { savePreviousStates() }
    }

    /// Extract the title from an AXUIElement window for use as part of the restore key.
    private func windowTitle(for window: AXUIElement) -> String {
        var titleValue: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
        return (titleValue as? String) ?? ""
    }

    func snap(position: SnapPosition, window: AXUIElement? = nil) throws {
        let targetWindow = try window ?? WindowAccessor.getFocusedWindow()

        guard let screen = ScreenManager.screen(for: targetWindow) else {
            return
        }

        // Save current state for restore, keyed by PID + window title
        if let currentFrame = try? WindowAccessor.getWindowFrame(targetWindow),
           let app = PreviousAppTracker.shared.targetApp {
            let key = WindowKey(pid: app.processIdentifier, title: windowTitle(for: targetWindow))
            previousStates[key] = WindowState(frame: currentFrame, screen: screen)
        }

        let targetFrame = calculator.frame(for: position, on: screen)
        try WindowAccessor.setWindowFrameAnimated(targetWindow, frame: targetFrame)

        if let bundleId = PreviousAppTracker.shared.targetApp?.bundleIdentifier {
            WindowMemoryStore.shared.rememberWindow(bundleIdentifier: bundleId, frame: targetFrame)
        }
    }

    func restore(window: AXUIElement? = nil) throws {
        let targetWindow = try window ?? WindowAccessor.getFocusedWindow()

        guard let app = PreviousAppTracker.shared.targetApp else {
            return
        }

        let key = WindowKey(pid: app.processIdentifier, title: windowTitle(for: targetWindow))
        guard let previousState = previousStates[key] else {
            logger.debug("No restore state found for window '\(key.title)' (pid \(key.pid))")
            return
        }

        try WindowAccessor.setWindowFrame(targetWindow, frame: previousState.frame)
        previousStates.removeValue(forKey: key)
    }

    func moveToNextScreen(window: AXUIElement? = nil) throws {
        let targetWindow = try window ?? WindowAccessor.getFocusedWindow()

        guard let currentScreen = ScreenManager.screen(for: targetWindow),
              let nextScreen = ScreenManager.nextScreen(after: currentScreen) else {
            return
        }

        let currentFrame = try WindowAccessor.getWindowFrame(targetWindow)

        // Calculate relative position on current screen
        let relativeX = (currentFrame.origin.x - currentScreen.visibleFrame.origin.x) / currentScreen.visibleFrame.width
        let relativeY = (currentFrame.origin.y - currentScreen.visibleFrame.origin.y) / currentScreen.visibleFrame.height
        let relativeW = currentFrame.width / currentScreen.visibleFrame.width
        let relativeH = currentFrame.height / currentScreen.visibleFrame.height

        // Apply relative position to next screen
        let newFrame = CGRect(
            x: nextScreen.visibleFrame.origin.x + relativeX * nextScreen.visibleFrame.width,
            y: nextScreen.visibleFrame.origin.y + relativeY * nextScreen.visibleFrame.height,
            width: relativeW * nextScreen.visibleFrame.width,
            height: relativeH * nextScreen.visibleFrame.height
        )

        try WindowAccessor.setWindowFrame(targetWindow, frame: newFrame)
    }

    func moveToPreviousScreen(window: AXUIElement? = nil) throws {
        let targetWindow = try window ?? WindowAccessor.getFocusedWindow()

        guard let currentScreen = ScreenManager.screen(for: targetWindow),
              let prevScreen = ScreenManager.previousScreen(before: currentScreen) else {
            return
        }

        let currentFrame = try WindowAccessor.getWindowFrame(targetWindow)

        // Calculate relative position on current screen
        let relativeX = (currentFrame.origin.x - currentScreen.visibleFrame.origin.x) / currentScreen.visibleFrame.width
        let relativeY = (currentFrame.origin.y - currentScreen.visibleFrame.origin.y) / currentScreen.visibleFrame.height
        let relativeW = currentFrame.width / currentScreen.visibleFrame.width
        let relativeH = currentFrame.height / currentScreen.visibleFrame.height

        // Apply relative position to previous screen
        let newFrame = CGRect(
            x: prevScreen.visibleFrame.origin.x + relativeX * prevScreen.visibleFrame.width,
            y: prevScreen.visibleFrame.origin.y + relativeY * prevScreen.visibleFrame.height,
            width: relativeW * prevScreen.visibleFrame.width,
            height: relativeH * prevScreen.visibleFrame.height
        )

        try WindowAccessor.setWindowFrame(targetWindow, frame: newFrame)
    }
}
