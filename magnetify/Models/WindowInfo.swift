import Foundation
import AppKit

struct WindowInfo: Identifiable, Equatable {
    let id: CGWindowID
    let ownerPID: pid_t
    let ownerName: String
    let title: String
    var frame: CGRect
    let isOnScreen: Bool

    var bundleIdentifier: String? {
        NSRunningApplication(processIdentifier: ownerPID)?.bundleIdentifier
    }
}
