import AppKit
import Combine
import Foundation
import os

final class StageManagerDetector: ObservableObject {

    static let shared = StageManagerDetector()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify", category: "StageManager")

    @Published private(set) var isStageManagerEnabled: Bool = false

    private init() {
        checkStageManager()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
    }

    func checkStageManager() {
        let defaults = UserDefaults(suiteName: "com.apple.WindowManager")
        let globallyEnabled = defaults?.bool(forKey: "GloballyEnabled") ?? false

        if isStageManagerEnabled != globallyEnabled {
            isStageManagerEnabled = globallyEnabled
            logger.info("Stage Manager is \(globallyEnabled ? "enabled" : "disabled")")
        }
    }

    @objc private func workspaceDidChange(_ notification: Notification) {
        checkStageManager()
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}
