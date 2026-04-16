import Foundation
import AppKit

enum SizeUnit: String, Codable {
    case pixels
    case percentage
}

struct SizeTemplate: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var width: CGFloat
    var height: CGFloat
    var unit: SizeUnit
    var centerOnScreen: Bool

    init(name: String, width: CGFloat, height: CGFloat, unit: SizeUnit = .pixels, centerOnScreen: Bool = true) {
        self.id = UUID()
        self.name = name
        self.width = width
        self.height = height
        self.unit = unit
        self.centerOnScreen = centerOnScreen
    }

    func absoluteSize(on screen: NSScreen) -> CGSize {
        switch unit {
        case .pixels:
            return CGSize(width: width, height: height)
        case .percentage:
            return CGSize(
                width: screen.visibleFrame.width * width / 100,
                height: screen.visibleFrame.height * height / 100
            )
        }
    }

    static let defaults: [SizeTemplate] = [
        SizeTemplate(name: String(localized: "sizeTemplate.default.small", defaultValue: "Small"), width: 800, height: 600),
        SizeTemplate(name: String(localized: "sizeTemplate.default.medium", defaultValue: "Medium"), width: 1200, height: 800),
        SizeTemplate(name: String(localized: "sizeTemplate.default.large", defaultValue: "Large"), width: 1600, height: 1000),
    ]
}
