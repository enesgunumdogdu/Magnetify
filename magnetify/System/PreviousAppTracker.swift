import Foundation
import AppKit
import os

/// Tracks the most recently frontmost application that is not Magnetify itself.
///
/// When the user opens Magnetify's menu bar panel, settings, or onboarding window,
/// Magnetify becomes the frontmost app. A raw `NSWorkspace.frontmostApplication`
/// lookup at that moment would target Magnetify's own windows instead of the user's
/// actual work window. This tracker remembers the previous foreground app so window
/// operations (snap, restore, move) can target the right window regardless of whether
/// Magnetify is currently active.
final class PreviousAppTracker {

    static let shared = PreviousAppTracker()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify", category: "PreviousAppTracker")
    private var observer: NSObjectProtocol?
    private(set) var lastForegroundApp: NSRunningApplication?

    private init() {}

    func start() {
        guard observer == nil else { return }

        // Seed with the current frontmost app if it isn't us.
        if let current = NSWorkspace.shared.frontmostApplication,
           current.bundleIdentifier != Bundle.main.bundleIdentifier {
            lastForegroundApp = current
        }

        let center = NSWorkspace.shared.notificationCenter
        observer = center.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }
            if app.bundleIdentifier == Bundle.main.bundleIdentifier {
                return
            }
            self?.lastForegroundApp = app
        }
    }

    func stop() {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            self.observer = nil
        }
    }

    /// The app the user is actually working with — the current frontmost app unless that
    /// is Magnetify itself, in which case the most recently tracked foreground app.
    /// Falls back to the topmost on-screen window's owner if no activation has been
    /// tracked yet (e.g. fresh launch before the user has switched apps).
    var targetApp: NSRunningApplication? {
        if let front = NSWorkspace.shared.frontmostApplication,
           front.bundleIdentifier != Bundle.main.bundleIdentifier {
            return front
        }
        if let last = lastForegroundApp, !last.isTerminated {
            return last
        }
        return topmostNonSelfWindowOwner()
    }

    /// Scans the window server's z-ordered list of on-screen windows and returns the
    /// running application that owns the frontmost window not belonging to Magnetify.
    private func topmostNonSelfWindowOwner() -> NSRunningApplication? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        let ownPID = ProcessInfo.processInfo.processIdentifier
        for window in windows {
            guard let layer = window[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            guard let pid = window[kCGWindowOwnerPID as String] as? pid_t, pid != ownPID else { continue }
            if let app = NSRunningApplication(processIdentifier: pid),
               app.activationPolicy == .regular,
               !app.isTerminated {
                return app
            }
        }
        return nil
    }

    deinit {
        stop()
    }
}
