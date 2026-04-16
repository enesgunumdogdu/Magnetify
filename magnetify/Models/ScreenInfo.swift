import Foundation
import AppKit

struct ScreenInfo: Identifiable, Equatable {
    let id: String
    let frame: CGRect
    let visibleFrame: CGRect
    let isMain: Bool
    let isVertical: Bool
    let scaleFactor: CGFloat

    init(screen: NSScreen) {
        self.id = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32)
            .map(String.init) ?? UUID().uuidString
        self.frame = screen.frame
        self.visibleFrame = screen.visibleFrame
        self.isMain = screen == NSScreen.main
        self.isVertical = screen.frame.height > screen.frame.width
        self.scaleFactor = screen.backingScaleFactor
    }
}
