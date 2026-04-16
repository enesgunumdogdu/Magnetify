import Foundation
import AppKit
import Combine
import os

final class DragManager: ObservableObject {

    @Published private(set) var currentSnapPosition: SnapPosition?
    @Published private(set) var isShowingPreview: Bool = false

    private let mouseMonitor = MouseMonitor()
    private var dragZone: DragZone
    private let snapEngine: SnapEngine
    private var isWindowDrag = false
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify", category: "DragManager")

    init(dragZone: DragZone, snapEngine: SnapEngine) {
        self.dragZone = dragZone
        self.snapEngine = snapEngine
        setupCallbacks()
    }

    func startListening() {
        mouseMonitor.startMonitoring()
    }

    func stopListening() {
        mouseMonitor.stopMonitoring()
        hidePreview()
    }

    private func setupCallbacks() {
        mouseMonitor.onDragStarted = { [weak self] in
            self?.handleDragStarted()
        }

        mouseMonitor.onDragMoved = { [weak self] location in
            self?.handleDragMoved(to: location)
        }

        mouseMonitor.onDragEnded = { [weak self] location in
            self?.handleDragEnded(at: location)
        }
    }

    private func handleDragStarted() {
        // Only treat as window drag if the mouse is in the title bar area
        guard let window = try? WindowAccessor.getFocusedWindow(),
              let frame = try? WindowAccessor.getWindowFrame(window) else {
            isWindowDrag = false
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        // Title bar is roughly the top 30 points of the window
        let titleBarHeight: CGFloat = 30
        let titleBarRect = CGRect(
            x: frame.origin.x,
            y: frame.origin.y + frame.height - titleBarHeight,
            width: frame.width,
            height: titleBarHeight
        )
        isWindowDrag = titleBarRect.contains(mouseLocation)

        if isWindowDrag {
            logger.debug("Window drag detected at title bar")
        }
    }

    private func handleDragMoved(to location: CGPoint) {
        guard isWindowDrag else { return }

        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(location) }) else {
            hidePreview()
            return
        }

        if let position = dragZone.snapPosition(for: location, on: screen) {
            if position != currentSnapPosition {
                currentSnapPosition = position
                showPreview(for: position, on: screen)
            }
        } else {
            hidePreview()
        }
    }

    private func handleDragEnded(at location: CGPoint) {
        guard isWindowDrag, let position = currentSnapPosition else {
            hidePreview()
            isWindowDrag = false
            return
        }

        snapEngine.snap(to: position)
        hidePreview()
        isWindowDrag = false
    }

    private func showPreview(for position: SnapPosition, on screen: NSScreen) {
        isShowingPreview = true
        SnapPreviewWindowController.shared.show(for: position, on: screen, gap: snapEngine.gap)
    }

    func updateSensitivity(_ sensitivity: CGFloat) {
        dragZone.sensitivity = sensitivity
    }

    private func hidePreview() {
        currentSnapPosition = nil
        isShowingPreview = false
        SnapPreviewWindowController.shared.hide()
    }
}
