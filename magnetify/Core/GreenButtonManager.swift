import AppKit
import os.log

/// Attaches a snap-position menu to the zoom (green) button of Magnetify's
/// own windows (e.g. the Settings window).
///
/// **Design note:** A window manager needs to snap *other* apps' windows, not
/// just its own.  Intercepting the green button of an arbitrary app would
/// require complex Accessibility event tapping, which is fragile and
/// unnecessary.  Snap-zone functionality for any focused window is already
/// exposed through:
///   • The menu-bar icon (SnapGridView)
///   • Global keyboard shortcuts (ShortcutManager)
///   • Drag-to-edge snapping (DragManager)
///
/// This manager therefore only customises the zoom button on Magnetify's own
/// windows, giving a consistent experience when the user interacts with the
/// Settings panel.
final class GreenButtonManager: NSObject {

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify",
        category: "GreenButtonManager"
    )

    private let snapEngine: SnapEngine
    private var trackedWindows: Set<ObjectIdentifier> = []
    private var windowObserver: Any?

    // MARK: - Init

    init(snapEngine: SnapEngine) {
        self.snapEngine = snapEngine
        super.init()
    }

    // MARK: - Public

    func startMonitoring() {
        // Observe Magnetify's own windows becoming key so we can attach the
        // snap menu lazily to their zoom button.
        windowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let window = notification.object as? NSWindow,
                  window.isKind(of: NSWindow.self),
                  NSApp.windows.contains(window) else { return }
            self.configureZoomButton(for: window)
        }

        // Also configure any windows that already exist at launch.
        for window in NSApp.windows {
            configureZoomButton(for: window)
        }

        Self.logger.debug("Started monitoring Magnetify windows for zoom-button menu")
    }

    func stopMonitoring() {
        if let observer = windowObserver {
            NotificationCenter.default.removeObserver(observer)
            windowObserver = nil
        }
        trackedWindows.removeAll()
        Self.logger.debug("Stopped monitoring zoom-button menu")
    }

    // MARK: - Private – Window Setup

    private func configureZoomButton(for window: NSWindow) {
        let id = ObjectIdentifier(window)
        guard !trackedWindows.contains(id) else { return }
        trackedWindows.insert(id)

        guard let zoomButton = window.standardWindowButton(.zoomButton) else { return }
        zoomButton.menu = buildSnapMenu()
    }

    // MARK: - Private – Menu Construction

    private func buildSnapMenu() -> NSMenu {
        let menu = NSMenu(
            title: String(
                localized: "greenButton.menu.title",
                defaultValue: "Snap Window"
            )
        )

        for (index, category) in SnapCategory.allCases.enumerated() {
            // Category header (disabled, acts as a label)
            let header = NSMenuItem()
            header.title = category.displayName
            header.isEnabled = false

            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
            header.attributedTitle = NSAttributedString(
                string: category.displayName,
                attributes: attributes
            )
            menu.addItem(header)

            // Position items
            for position in category.positions {
                let item = NSMenuItem(
                    title: position.displayName,
                    action: #selector(snapMenuItemClicked(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = position
                item.image = NSImage(
                    systemSymbolName: position.icon,
                    accessibilityDescription: position.displayName
                )
                menu.addItem(item)
            }

            // Separator between categories (not after the last one)
            if index < SnapCategory.allCases.count - 1 {
                menu.addItem(.separator())
            }
        }

        return menu
    }

    // MARK: - Actions

    @objc private func snapMenuItemClicked(_ sender: NSMenuItem) {
        guard let position = sender.representedObject as? SnapPosition else { return }
        snapEngine.snap(to: position)
    }

    // MARK: - Deinit

    deinit {
        stopMonitoring()
    }
}
