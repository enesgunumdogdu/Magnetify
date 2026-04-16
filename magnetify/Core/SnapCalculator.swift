import Foundation
import AppKit

struct SnapCalculator {

    var gap: CGFloat

    init(gap: CGFloat = 0) {
        self.gap = gap
    }

    func frame(for position: SnapPosition, on screen: NSScreen) -> CGRect {
        let visibleFrame = screen.visibleFrame
        return frame(for: position, in: visibleFrame)
    }

    func frame(for position: SnapPosition, in area: CGRect) -> CGRect {
        let x = area.origin.x + gap
        let y = area.origin.y + gap
        let w = area.width - (gap * 2)
        let h = area.height - (gap * 2)
        let halfW = (w - gap) / 2
        let halfH = (h - gap) / 2
        let thirdW = (w - gap * 2) / 3
        let twoThirdW = thirdW * 2 + gap

        switch position {
        case .leftHalf:
            return CGRect(x: x, y: y, width: halfW, height: h)
        case .rightHalf:
            return CGRect(x: x + halfW + gap, y: y, width: halfW, height: h)
        case .topHalf:
            return CGRect(x: x, y: y + halfH + gap, width: w, height: halfH)
        case .bottomHalf:
            return CGRect(x: x, y: y, width: w, height: halfH)
        case .topLeft:
            return CGRect(x: x, y: y + halfH + gap, width: halfW, height: halfH)
        case .topRight:
            return CGRect(x: x + halfW + gap, y: y + halfH + gap, width: halfW, height: halfH)
        case .bottomLeft:
            return CGRect(x: x, y: y, width: halfW, height: halfH)
        case .bottomRight:
            return CGRect(x: x + halfW + gap, y: y, width: halfW, height: halfH)
        case .leftThird:
            return CGRect(x: x, y: y, width: thirdW, height: h)
        case .centerThird:
            return CGRect(x: x + thirdW + gap, y: y, width: thirdW, height: h)
        case .rightThird:
            return CGRect(x: x + thirdW * 2 + gap * 2, y: y, width: thirdW, height: h)
        case .leftTwoThirds:
            return CGRect(x: x, y: y, width: twoThirdW, height: h)
        case .rightTwoThirds:
            return CGRect(x: x + thirdW + gap, y: y, width: twoThirdW, height: h)
        case .fullscreen:
            return CGRect(x: x, y: y, width: w, height: h)
        case .center:
            let centerW = w * 0.7
            let centerH = h * 0.7
            return CGRect(
                x: x + (w - centerW) / 2,
                y: y + (h - centerH) / 2,
                width: centerW,
                height: centerH
            )
        case .moveToNextScreen, .moveToPreviousScreen:
            // These are handled by SnapEngine directly, not through frame calculation
            return area
        case .restore:
            return area
        }
    }
}
