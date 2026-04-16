import Foundation
import AppKit
import Combine
import os

private let logger = Logger(subsystem: "com.example.magnetify", category: "AccessibilityManager")

final class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()

    @Published private(set) var isAccessibilityGranted: Bool = false

    private var pollTimer: Timer?

    private init() {
        checkAccessibility()
    }

    func checkAccessibility() {
        isAccessibilityGranted = AXIsProcessTrusted()
    }

    func requestAccessibility() {
        // Adds the app to the Accessibility list and prompts the system dialog
        // the first time. Subsequent calls silently return, so we also open
        // System Settings directly to guide the user.
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: NSDictionary = [prompt: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)

        openAccessibilitySettings()
        startPolling()
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        if !NSWorkspace.shared.open(url) {
            logger.error("Failed to open Accessibility settings pane")
        }
    }

    func startPolling() {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkAccessibility()
            if self?.isAccessibilityGranted == true {
                self?.stopPolling()
            }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    deinit {
        stopPolling()
    }
}
