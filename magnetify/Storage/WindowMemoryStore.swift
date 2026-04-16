import Foundation
import AppKit
import Combine
import os

struct RememberedWindow: Codable, Equatable {
    let bundleIdentifier: String
    let frame: CodableRect
    let updatedAt: Date
}

final class WindowMemoryStore: ObservableObject {

    static let shared = WindowMemoryStore()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify",
        category: "WindowMemory"
    )

    @Published private(set) var memories: [String: RememberedWindow] = [:]

    private let storageKey = "windowMemories"
    private var appLaunchObserver: Any?
    private var isEnabled: Bool { SettingsStore.shared.enableWindowMemory }

    private init() {
        load()
    }

    // MARK: - Persistence

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: RememberedWindow].self, from: data) {
            self.memories = decoded
            logger.debug("Loaded \(decoded.count) window memories")
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(memories) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    // MARK: - Remember

    func rememberWindow(bundleIdentifier: String, frame: CGRect) {
        guard isEnabled else { return }

        let memory = RememberedWindow(
            bundleIdentifier: bundleIdentifier,
            frame: CodableRect(rect: frame),
            updatedAt: Date()
        )
        memories[bundleIdentifier] = memory
        save()
        logger.debug("Remembered window position for \(bundleIdentifier)")
    }

    func rememberCurrentFocusedWindow() {
        guard isEnabled else { return }

        guard let app = PreviousAppTracker.shared.targetApp,
              let bundleId = app.bundleIdentifier else { return }

        guard let window = try? WindowAccessor.getFocusedWindow(),
              let frame = try? WindowAccessor.getWindowFrame(window) else { return }

        rememberWindow(bundleIdentifier: bundleId, frame: frame)
    }

    // MARK: - Restore

    func restoreWindow(for bundleIdentifier: String) {
        guard isEnabled,
              let memory = memories[bundleIdentifier] else { return }

        guard let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == bundleIdentifier
        }), !app.isTerminated else { return }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windowsRef
        ) == .success,
              let windows = windowsRef as? [AXUIElement],
              let window = windows.first else { return }

        do {
            try WindowAccessor.setWindowFrame(window, frame: memory.frame.cgRect)
            logger.info("Restored window position for \(bundleIdentifier)")
        } catch {
            logger.error("Failed to restore window for \(bundleIdentifier): \(error.localizedDescription)")
        }
    }

    // MARK: - App Launch Observation

    func startObserving() {
        guard appLaunchObserver == nil else { return }

        appLaunchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleId = app.bundleIdentifier else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self?.restoreWindow(for: bundleId)
            }
        }

        logger.info("Started observing app launches for window memory")
    }

    func stopObserving() {
        if let observer = appLaunchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            appLaunchObserver = nil
            logger.info("Stopped observing app launches for window memory")
        }
    }

    // MARK: - Clear

    func clearMemory(for bundleIdentifier: String) {
        memories.removeValue(forKey: bundleIdentifier)
        save()
    }

    func clearAll() {
        memories.removeAll()
        save()
    }

    deinit {
        stopObserving()
    }
}
