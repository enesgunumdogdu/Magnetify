import Foundation
import SwiftUI

enum SnapPosition: String, CaseIterable, Codable, Identifiable {
    // Halves
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf

    // Quarters
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    // Thirds
    case leftThird
    case centerThird
    case rightThird

    // Two-thirds
    case leftTwoThirds
    case rightTwoThirds

    // Monitor
    case moveToNextScreen
    case moveToPreviousScreen

    // Other
    case fullscreen
    case center
    case restore

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .leftHalf: return String(localized: "snap.position.leftHalf", defaultValue: "Left Half")
        case .rightHalf: return String(localized: "snap.position.rightHalf", defaultValue: "Right Half")
        case .topHalf: return String(localized: "snap.position.topHalf", defaultValue: "Top Half")
        case .bottomHalf: return String(localized: "snap.position.bottomHalf", defaultValue: "Bottom Half")
        case .topLeft: return String(localized: "snap.position.topLeft", defaultValue: "Top Left")
        case .topRight: return String(localized: "snap.position.topRight", defaultValue: "Top Right")
        case .bottomLeft: return String(localized: "snap.position.bottomLeft", defaultValue: "Bottom Left")
        case .bottomRight: return String(localized: "snap.position.bottomRight", defaultValue: "Bottom Right")
        case .leftThird: return String(localized: "snap.position.leftThird", defaultValue: "Left Third")
        case .centerThird: return String(localized: "snap.position.centerThird", defaultValue: "Center Third")
        case .rightThird: return String(localized: "snap.position.rightThird", defaultValue: "Right Third")
        case .leftTwoThirds: return String(localized: "snap.position.leftTwoThirds", defaultValue: "Left Two Thirds")
        case .rightTwoThirds: return String(localized: "snap.position.rightTwoThirds", defaultValue: "Right Two Thirds")
        case .moveToNextScreen: return String(localized: "snap.position.moveToNextScreen", defaultValue: "Next Monitor")
        case .moveToPreviousScreen: return String(localized: "snap.position.moveToPreviousScreen", defaultValue: "Previous Monitor")
        case .fullscreen: return String(localized: "snap.position.fullscreen", defaultValue: "Fullscreen")
        case .center: return String(localized: "snap.position.center", defaultValue: "Center")
        case .restore: return String(localized: "snap.position.restore", defaultValue: "Restore")
        }
    }

    var icon: String {
        switch self {
        case .leftHalf: return "rectangle.lefthalf.filled"
        case .rightHalf: return "rectangle.righthalf.filled"
        case .topHalf: return "rectangle.tophalf.filled"
        case .bottomHalf: return "rectangle.bottomhalf.filled"
        case .topLeft: return "rectangle.inset.topleft.filled"
        case .topRight: return "rectangle.inset.topright.filled"
        case .bottomLeft: return "rectangle.inset.bottomleft.filled"
        case .bottomRight: return "rectangle.inset.bottomright.filled"
        case .leftThird: return "rectangle.split.3x1"
        case .centerThird: return "square.split.1x2"
        case .rightThird: return "rectangle.split.3x1.fill"
        case .leftTwoThirds: return "rectangle.lefthalf.filled"
        case .rightTwoThirds: return "rectangle.righthalf.filled"
        case .moveToNextScreen: return "display.2"
        case .moveToPreviousScreen: return "display.2"
        case .fullscreen: return "rectangle.fill"
        case .center: return "rectangle.center.inset.filled"
        case .restore: return "arrow.uturn.backward"
        }
    }

    var category: SnapCategory {
        switch self {
        case .leftHalf, .rightHalf, .topHalf, .bottomHalf:
            return .halves
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            return .quarters
        case .leftThird, .centerThird, .rightThird:
            return .thirds
        case .leftTwoThirds, .rightTwoThirds:
            return .twoThirds
        case .moveToNextScreen, .moveToPreviousScreen:
            return .monitor
        case .fullscreen, .center, .restore:
            return .other
        }
    }
}

enum SnapCategory: String, CaseIterable, Identifiable {
    case halves
    case quarters
    case thirds
    case twoThirds
    case monitor
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .halves: return String(localized: "snap.category.halves", defaultValue: "Halves")
        case .quarters: return String(localized: "snap.category.quarters", defaultValue: "Quarters")
        case .thirds: return String(localized: "snap.category.thirds", defaultValue: "Thirds")
        case .twoThirds: return String(localized: "snap.category.twoThirds", defaultValue: "Two Thirds")
        case .monitor: return String(localized: "snap.category.monitor", defaultValue: "Monitor")
        case .other: return String(localized: "snap.category.other", defaultValue: "Other")
        }
    }

    var positions: [SnapPosition] {
        SnapPosition.allCases.filter { $0.category == self }
    }
}
