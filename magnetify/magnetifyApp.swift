import SwiftUI

@main
struct MagnetifyApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar app - no main window
        Settings {
            SettingsView()
        }
    }
}
