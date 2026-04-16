import SwiftUI
import AppKit

final class OnboardingWindowController {

    static let shared = OnboardingWindowController()

    private var window: NSWindow?

    private init() {}

    func show(onComplete: @escaping () -> Void) {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let onboardingView = OnboardingView {
            onComplete()
            self.window?.close()
            self.window = nil
        }

        let hostingController = NSHostingController(rootView: onboardingView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = String(localized: "onboarding.window.title", defaultValue: "Welcome to Magnetify")
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.level = .floating

        self.window = window

        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Reset level after activation so it doesn't stay above everything
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            window.level = .normal
        }
    }
}
