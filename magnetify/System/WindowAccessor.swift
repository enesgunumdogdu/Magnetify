import Foundation
import AppKit
import os.log

final class WindowAccessor {

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify", category: "WindowAccessor")

    enum AccessorError: Error {
        case noFocusedWindow
        case attributeReadFailed
        case attributeWriteFailed
        case accessibilityNotGranted
        case unexpectedType
    }

    // MARK: - Coordinate Conversion

    /// Convert NSScreen coordinates (bottom-left origin) to AXUIElement coordinates (top-left origin).
    static func convertToAXCoordinates(_ frame: CGRect) -> CGRect {
        guard let mainScreen = NSScreen.screens.first else { return frame }
        let mainScreenHeight = mainScreen.frame.height
        return CGRect(
            x: frame.origin.x,
            y: mainScreenHeight - frame.origin.y - frame.height,
            width: frame.width,
            height: frame.height
        )
    }

    /// Convert AXUIElement coordinates (top-left origin) to NSScreen coordinates (bottom-left origin).
    static func convertFromAXCoordinates(_ frame: CGRect) -> CGRect {
        guard let mainScreen = NSScreen.screens.first else { return frame }
        let mainScreenHeight = mainScreen.frame.height
        return CGRect(
            x: frame.origin.x,
            y: mainScreenHeight - frame.origin.y - frame.height,
            width: frame.width,
            height: frame.height
        )
    }

    static func getFocusedWindow() throws -> AXUIElement {
        guard AXIsProcessTrusted() else {
            throw AccessorError.accessibilityNotGranted
        }

        guard let targetApp = PreviousAppTracker.shared.targetApp else {
            throw AccessorError.noFocusedWindow
        }

        let appElement = AXUIElementCreateApplication(targetApp.processIdentifier)

        var focusedWindow: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)

        guard result == .success, let window = focusedWindow else {
            throw AccessorError.noFocusedWindow
        }

        // Verify the CFTypeRef is actually an AXUIElement by checking its type ID
        guard CFGetTypeID(window) == AXUIElementGetTypeID() else {
            logger.error("Focused window CFTypeRef is not an AXUIElement")
            throw AccessorError.unexpectedType
        }
        // Safe after type ID check above
        let axElement = unsafeBitCast(window, to: AXUIElement.self)
        return axElement
    }

    static func getWindowFrame(_ window: AXUIElement) throws -> CGRect {
        let position = try getWindowPosition(window)
        let size = try getWindowSize(window)
        let axFrame = CGRect(origin: position, size: size)
        return convertFromAXCoordinates(axFrame)
    }

    static func getWindowPosition(_ window: AXUIElement) throws -> CGPoint {
        var positionValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)

        guard result == .success, let value = positionValue else {
            throw AccessorError.attributeReadFailed
        }

        guard CFGetTypeID(value) == AXValueGetTypeID() else {
            logger.error("Position attribute is not an AXValue")
            throw AccessorError.unexpectedType
        }
        var point = CGPoint.zero
        let axValue = unsafeBitCast(value, to: AXValue.self)
        AXValueGetValue(axValue, .cgPoint, &point)
        return point
    }

    static func getWindowSize(_ window: AXUIElement) throws -> CGSize {
        var sizeValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)

        guard result == .success, let value = sizeValue else {
            throw AccessorError.attributeReadFailed
        }

        guard CFGetTypeID(value) == AXValueGetTypeID() else {
            logger.error("Size attribute is not an AXValue")
            throw AccessorError.unexpectedType
        }
        var size = CGSize.zero
        let axValue = unsafeBitCast(value, to: AXValue.self)
        AXValueGetValue(axValue, .cgSize, &size)
        return size
    }

    static func setWindowFrame(_ window: AXUIElement, frame: CGRect) throws {
        let axFrame = convertToAXCoordinates(frame)
        try setWindowPosition(window, position: axFrame.origin)
        try setWindowSize(window, size: axFrame.size)
    }

    static func setWindowPosition(_ window: AXUIElement, position: CGPoint) throws {
        var point = position
        guard let value = AXValueCreate(.cgPoint, &point) else {
            throw AccessorError.attributeWriteFailed
        }

        let result = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
        guard result == .success else {
            throw AccessorError.attributeWriteFailed
        }
    }

    static func setWindowSize(_ window: AXUIElement, size: CGSize) throws {
        var newSize = size
        guard let value = AXValueCreate(.cgSize, &newSize) else {
            throw AccessorError.attributeWriteFailed
        }

        let result = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
        guard result == .success else {
            throw AccessorError.attributeWriteFailed
        }
    }

    static func setWindowFrameAnimated(_ window: AXUIElement, frame: CGRect, duration: TimeInterval = 0.15) throws {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            try setWindowFrame(window, frame: frame)
            return
        }

        let currentFrame = try getWindowFrame(window)
        let steps = 6
        let interval = duration / Double(steps)

        for i in 1...steps {
            let progress = CGFloat(i) / CGFloat(steps)
            let eased = progress * progress * (3 - 2 * progress) // smoothstep

            let x = currentFrame.origin.x + (frame.origin.x - currentFrame.origin.x) * eased
            let y = currentFrame.origin.y + (frame.origin.y - currentFrame.origin.y) * eased
            let w = currentFrame.width + (frame.width - currentFrame.width) * eased
            let h = currentFrame.height + (frame.height - currentFrame.height) * eased

            let intermediateFrame = CGRect(x: x, y: y, width: w, height: h)
            let delay = TimeInterval(i) * interval

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                try? setWindowFrame(window, frame: intermediateFrame)
            }
        }
    }
}
