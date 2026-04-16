import Foundation

struct AppRule: Codable, Identifiable, Equatable {
    let id: UUID
    var bundleIdentifier: String
    var appName: String
    var position: SnapPosition
    var isEnabled: Bool

    init(bundleIdentifier: String, appName: String, position: SnapPosition, isEnabled: Bool = true) {
        self.id = UUID()
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.position = position
        self.isEnabled = isEnabled
    }
}
