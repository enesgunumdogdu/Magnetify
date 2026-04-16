import Foundation
import AppKit
import Combine

final class MouseMonitor: ObservableObject {

    @Published private(set) var currentPosition: CGPoint = .zero
    @Published private(set) var isDragging: Bool = false

    private var globalMonitor: Any?
    private var localMonitor: Any?

    var onDragStarted: (() -> Void)?
    var onDragMoved: ((CGPoint) -> Void)?
    var onDragEnded: ((CGPoint) -> Void)?

    func startMonitoring() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDragged, .leftMouseUp]
        ) { [weak self] event in
            self?.handleEvent(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDragged, .leftMouseUp]
        ) { [weak self] event in
            self?.handleEvent(event)
            return event
        }
    }

    func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func handleEvent(_ event: NSEvent) {
        let location = NSEvent.mouseLocation
        currentPosition = location

        switch event.type {
        case .leftMouseDragged:
            if !isDragging {
                isDragging = true
                onDragStarted?()
            }
            onDragMoved?(location)

        case .leftMouseUp:
            if isDragging {
                isDragging = false
                onDragEnded?(location)
            }

        default:
            break
        }
    }

    deinit {
        stopMonitoring()
    }
}
