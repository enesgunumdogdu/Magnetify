import Foundation
import AppKit

struct DragZone {

    var sensitivity: CGFloat

    init(sensitivity: CGFloat = 5) {
        self.sensitivity = sensitivity
    }

    func snapPosition(for mouseLocation: CGPoint, on screen: NSScreen) -> SnapPosition? {
        let frame = screen.visibleFrame
        let threshold = sensitivity

        let stageManagerOffset: CGFloat = StageManagerDetector.shared.isStageManagerEnabled ? 150 : 0
        let isNearLeft = mouseLocation.x - frame.minX - stageManagerOffset <= threshold
        let isNearRight = frame.maxX - mouseLocation.x <= threshold
        let isNearTop = frame.maxY - mouseLocation.y <= threshold
        let isNearBottom = mouseLocation.y - frame.minY <= threshold

        // Corners (highest priority)
        if isNearLeft && isNearTop { return .topLeft }
        if isNearRight && isNearTop { return .topRight }
        if isNearLeft && isNearBottom { return .bottomLeft }
        if isNearRight && isNearBottom { return .bottomRight }

        // Edges
        if isNearTop { return .fullscreen }
        if isNearLeft { return .leftHalf }
        if isNearRight { return .rightHalf }

        // Bottom edge: center 60% → bottomHalf, outer 20% each → thirds
        if isNearBottom {
            let relativeX = mouseLocation.x - frame.minX
            let ratio = relativeX / frame.width

            if ratio < 0.2 {
                return .leftThird
            } else if ratio > 0.8 {
                return .rightThird
            } else {
                return .bottomHalf
            }
        }

        return nil
    }
}
