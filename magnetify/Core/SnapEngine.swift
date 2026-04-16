import Foundation
import AppKit
import Combine
import os

final class SnapEngine: ObservableObject {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify", category: "SnapEngine")

    var windowController: WindowController
    let shortcutManager: ShortcutManager
    var calculator: SnapCalculator

    @Published var gap: CGFloat
    private var lastSnapPosition: SnapPosition?

    // MARK: - Chain Mode
    private var isChainMode = false
    private var chainTimer: Timer?
    private var chainKeyMonitor: Any?

    init(gap: CGFloat = 0) {
        self.gap = gap
        self.calculator = SnapCalculator(gap: gap)
        self.windowController = WindowController(calculator: calculator)
        self.shortcutManager = ShortcutManager()

        setupShortcuts()
    }

    func snap(to position: SnapPosition) {
        switch position {
        case .restore:
            restore()
            return
        case .moveToNextScreen:
            moveToNextScreen()
            return
        case .moveToPreviousScreen:
            moveToPreviousScreen()
            return
        default:
            break
        }
        do {
            try windowController.snap(position: position)
            lastSnapPosition = position
        } catch {
            logger.error("Snap failed: \(error.localizedDescription)")
        }
    }

    func restore() {
        do {
            try windowController.restore()
        } catch {
            logger.error("Restore failed: \(error.localizedDescription)")
        }
    }

    func moveToNextScreen() {
        do {
            try windowController.moveToNextScreen()
        } catch {
            logger.error("Move to next screen failed: \(error.localizedDescription)")
        }
    }

    func moveToPreviousScreen() {
        do {
            try windowController.moveToPreviousScreen()
        } catch {
            logger.error("Move to previous screen failed: \(error.localizedDescription)")
        }
    }

    private func setupShortcuts() {
        shortcutManager.configure { [weak self] position in
            self?.snap(to: position)
        }
        shortcutManager.onChainMode = { [weak self] in
            self?.enterChainMode()
        }
    }

    func enterChainMode() {
        isChainMode = true
        chainTimer?.invalidate()
        chainTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.exitChainMode()
        }

        chainKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleChainKey(UInt32(event.keyCode))
        }
        logger.info("Entered chain mode")
    }

    func exitChainMode() {
        isChainMode = false
        chainTimer?.invalidate()
        chainTimer = nil
        if let monitor = chainKeyMonitor {
            NSEvent.removeMonitor(monitor)
            chainKeyMonitor = nil
        }
    }

    private func handleChainKey(_ keyCode: UInt32) {
        guard isChainMode else { return }
        exitChainMode()

        let chainMapping: [UInt32: SnapPosition] = [
            0x25: .leftHalf,              // L
            0x0F: .rightHalf,             // R
            0x11: .topHalf,               // T
            0x0B: .bottomHalf,            // B
            0x03: .fullscreen,            // F
            0x08: .center,                // C
            0x33: .restore,               // Delete
            0x2D: .moveToNextScreen,      // N
            0x23: .moveToPreviousScreen,  // P
        ]

        if let position = chainMapping[keyCode] {
            snap(to: position)
        }
    }

    func cycleInCategory() {
        let currentCategory = lastSnapPosition?.category ?? .halves
        let positions = currentCategory.positions.filter { $0 != .restore }

        guard !positions.isEmpty else { return }

        let currentIndex = positions.firstIndex(of: lastSnapPosition ?? positions[0]) ?? -1
        let nextIndex = (currentIndex + 1) % positions.count
        let nextPosition = positions[nextIndex]

        snap(to: nextPosition)
    }

    func startListening() {
        shortcutManager.registerAll()
        shortcutManager.registerChainModeHotkey()
    }

    func stopListening() {
        exitChainMode()
        shortcutManager.unregisterAll()
    }
}
