import Foundation
import AppKit
import Combine
import os

final class RuleStore: ObservableObject {
    static let shared = RuleStore()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify", category: "RuleStore")

    @Published var rules: [AppRule] {
        didSet { save() }
    }

    private let storageKey = "appRules"
    private var appLaunchObserver: Any?
    private var snapEngine: SnapEngine?

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([AppRule].self, from: data) {
            self.rules = decoded
        } else {
            self.rules = []
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func configure(snapEngine: SnapEngine) {
        self.snapEngine = snapEngine
    }

    func addRule(_ rule: AppRule) { rules.append(rule) }
    func deleteRule(id: UUID) { rules.removeAll { $0.id == id } }
    func updateRule(_ rule: AppRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        }
    }

    func startObserving() {
        stopObserving()
        appLaunchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleId = app.bundleIdentifier else { return }
            self?.applyRule(for: bundleId, pid: app.processIdentifier)
        }
    }

    func stopObserving() {
        if let observer = appLaunchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            appLaunchObserver = nil
        }
    }

    private func applyRule(for bundleIdentifier: String, pid: pid_t) {
        guard SettingsStore.shared.enableAppRules else { return }
        guard let rule = rules.first(where: { $0.bundleIdentifier == bundleIdentifier && $0.isEnabled }) else { return }

        // Delay to let the app create its window
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            let appElement = AXUIElementCreateApplication(pid)
            var windowsRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
                  let windows = windowsRef as? [AXUIElement],
                  let window = windows.first else { return }

            guard let screen = NSScreen.main else { return }
            let calculator = SnapCalculator(gap: SettingsStore.shared.snapGap)
            let frame = calculator.frame(for: rule.position, on: screen)

            do {
                try WindowAccessor.setWindowFrame(window, frame: frame)
                self?.logger.info("Applied rule for \(rule.appName): \(rule.position.rawValue)")
            } catch {
                self?.logger.error("Failed to apply rule for \(rule.appName): \(error.localizedDescription)")
            }
        }
    }

    deinit { stopObserving() }
}
