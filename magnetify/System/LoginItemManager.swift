import Foundation
import ServiceManagement
import os

final class LoginItemManager {

    static let shared = LoginItemManager()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify", category: "LoginItemManager")

    private init() {}

    var isLoginItemEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setLoginItemEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            logger.error("Failed to update login item: \(error.localizedDescription)")
        }
    }
}
