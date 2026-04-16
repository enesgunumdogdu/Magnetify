import SwiftUI
import AppKit

final class MenuBarManager: NSObject {

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let snapEngine: SnapEngine

    init(snapEngine: SnapEngine) {
        self.snapEngine = snapEngine
        super.init()
    }

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "rectangle.split.2x2", accessibilityDescription: String(localized: "accessibility.menuBarIcon", defaultValue: "Magnetify"))
            button.action = #selector(togglePopover)
            button.target = self
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: SnapGridView(
                onSnap: { [weak self] position in
                    self?.popover?.performClose(nil)
                    // Small delay to let popover close before snapping
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self?.snapEngine.snap(to: position)
                    }
                },
                onCycle: { [weak self] in
                    self?.popover?.performClose(nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self?.snapEngine.cycleInCategory()
                    }
                },
                onQuit: {
                    NSApp.terminate(nil)
                },
                onSettings: { [weak self] in
                    self?.popover?.performClose(nil)
                    SettingsWindowController.shared.show()
                }
            )
        )

        self.popover = popover
    }

    func updateVisibility(visible: Bool) {
        statusItem?.isVisible = visible
    }

    @objc private func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
