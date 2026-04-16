import Foundation
import CoreGraphics

struct WindowSnapshot: Codable, Equatable, Identifiable {
    let id: UUID
    let bundleIdentifier: String
    let appName: String
    let frame: CodableRect

    init(bundleIdentifier: String, appName: String, frame: CGRect) {
        self.id = UUID()
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.frame = CodableRect(rect: frame)
    }
}

struct CodableRect: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat

    init(rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

struct WorkspaceProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var windows: [WindowSnapshot]
    var assignedApps: [String]
    let createdAt: Date
    var updatedAt: Date

    init(name: String, icon: String = "rectangle.3.group", windows: [WindowSnapshot] = [], assignedApps: [String] = []) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.windows = windows
        self.assignedApps = assignedApps
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
