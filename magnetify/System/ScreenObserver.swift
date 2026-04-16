import Foundation
import AppKit
import Combine

final class ScreenObserver: ObservableObject {

    @Published private(set) var screens: [ScreenInfo] = []

    init() {
        refreshScreens()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func refreshScreens() {
        screens = NSScreen.screens.map { ScreenInfo(screen: $0) }
    }

    func screen(containing point: CGPoint) -> ScreenInfo? {
        screens.first { $0.frame.contains(point) }
    }

    func mainScreen() -> ScreenInfo? {
        screens.first { $0.isMain }
    }

    @objc private func screensDidChange(_ notification: Notification) {
        refreshScreens()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
