import SwiftUI
import AppKit

final class SettingsWindowController: NSObject, NSWindowDelegate {

    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private override init() { super.init() }

    func show() {
        // While Settings is open, behave like a regular app: appear in Dock and
        // Cmd-Tab, let the user switch away and back. Reverted on close.
        NSApp.setActivationPolicy(.regular)

        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = String(localized: "settings.window.title", defaultValue: "Magnetify Settings")
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()
        window.setFrameAutosaveName("SettingsWindow")
        window.isReleasedWhenClosed = false
        window.delegate = self

        // Disable zoom (green) button to prevent full-screen
        window.standardWindowButton(.zoomButton)?.isEnabled = false

        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        // Restore menu bar agent behavior once Settings is dismissed.
        NSApp.setActivationPolicy(.accessory)
    }
}
