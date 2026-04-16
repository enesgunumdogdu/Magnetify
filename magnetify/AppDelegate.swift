import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var menuBarManager: MenuBarManager?
    private var snapEngine: SnapEngine?
    private var dragManager: DragManager?
    private var greenButtonManager: GreenButtonManager?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = SettingsStore.shared

        // Track the user's actual working app so window operations target the
        // right window even when Magnetify's own UI is frontmost.
        PreviousAppTracker.shared.start()

        // Initialize core engine
        let engine = SnapEngine(gap: settings.snapGap)
        engine.shortcutManager.bindings = ShortcutStore.shared.bindings
        self.snapEngine = engine

        // Initialize drag manager
        let dragZone = DragZone(sensitivity: settings.snapSensitivity)
        let drag = DragManager(dragZone: dragZone, snapEngine: engine)
        self.dragManager = drag

        // Initialize menu bar
        let menuBar = MenuBarManager(snapEngine: engine)
        menuBar.setup()
        self.menuBarManager = menuBar

        // Start listening
        if settings.enableKeyboardShortcuts {
            engine.startListening()
        }

        if settings.enableDragToSnap {
            drag.startListening()
        }

        // Initialize green button snap menu
        if settings.enableGreenButtonSnap {
            let greenButton = GreenButtonManager(snapEngine: engine)
            greenButton.startMonitoring()
            self.greenButtonManager = greenButton
        }

        // Start window memory observation
        if settings.enableWindowMemory {
            WindowMemoryStore.shared.startObserving()
        }

        // Start app rules observation
        RuleStore.shared.configure(snapEngine: engine)
        RuleStore.shared.startObserving()

        // Show onboarding or start
        if !settings.hasCompletedOnboarding {
            OnboardingWindowController.shared.show {
                settings.hasCompletedOnboarding = true
            }
        }

        observeSettings()
    }

    func applicationWillTerminate(_ notification: Notification) {
        snapEngine?.stopListening()
        dragManager?.stopListening()
        greenButtonManager?.stopMonitoring()
        WindowMemoryStore.shared.stopObserving()
        RuleStore.shared.stopObserving()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Menu bar app must stay alive when all windows are closed
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Settings Observers

    private func observeSettings() {
        let settings = SettingsStore.shared

        // @AppStorage properties don't expose Combine publishers outside SwiftUI views.
        // Observe objectWillChange which fires whenever any @AppStorage value changes,
        // then read the current values and apply them.
        settings.objectWillChange
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applySettings()
            }
            .store(in: &cancellables)

        // Re-register shortcuts when individual bindings change in ShortcutStore.
        ShortcutStore.shared.$bindings
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newBindings in
                self?.snapEngine?.shortcutManager.bindings = newBindings
                if SettingsStore.shared.enableKeyboardShortcuts {
                    self?.snapEngine?.shortcutManager.registerAll()
                }
            }
            .store(in: &cancellables)
    }

    private func applySettings() {
        let settings = SettingsStore.shared

        // Menu bar visibility
        menuBarManager?.updateVisibility(visible: settings.showMenuBarIcon)

        // Drag-to-snap
        if settings.enableDragToSnap {
            dragManager?.startListening()
        } else {
            dragManager?.stopListening()
        }

        // Keyboard shortcuts
        if settings.enableKeyboardShortcuts {
            snapEngine?.startListening()
        } else {
            snapEngine?.stopListening()
        }

        // Snap gap
        if let engine = snapEngine {
            let newGap = CGFloat(settings.snapGap)
            engine.gap = newGap
            engine.calculator.gap = newGap
            engine.windowController.calculator = engine.calculator
        }

        // Snap sensitivity
        dragManager?.updateSensitivity(CGFloat(settings.snapSensitivity))

        // Window memory
        if settings.enableWindowMemory {
            WindowMemoryStore.shared.startObserving()
        } else {
            WindowMemoryStore.shared.stopObserving()
        }
    }
}
