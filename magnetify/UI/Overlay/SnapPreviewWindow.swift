import Foundation
import AppKit

final class SnapPreviewWindowController {

    static let shared = SnapPreviewWindowController()

    private var previewWindow: NSWindow?

    private init() {}

    func show(for position: SnapPosition, on screen: NSScreen, gap: CGFloat) {
        let calculator = SnapCalculator(gap: gap)
        let frame = calculator.frame(for: position, on: screen)

        if previewWindow == nil {
            createWindow()
        }

        guard let window = previewWindow else { return }

        let settings = SettingsStore.shared
        let isHighContrast = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        let borderWidth: CGFloat = isHighContrast ? 4 : 2
        let fillOpacity = isHighContrast ? min(settings.previewOpacity + 0.2, 0.8) : settings.previewOpacity
        let borderOpacity: CGFloat = isHighContrast ? 0.9 : 0.6

        if let contentView = window.contentView {
            contentView.wantsLayer = true
            contentView.layer?.backgroundColor = settings.previewColor.withAlphaComponent(fillOpacity).cgColor
            contentView.layer?.cornerRadius = 10
            contentView.layer?.borderWidth = borderWidth
            contentView.layer?.borderColor = settings.previewColor.withAlphaComponent(borderOpacity).cgColor

            // Inner glow effect via shadow
            contentView.layer?.shadowColor = settings.previewColor.withAlphaComponent(0.4).cgColor
            contentView.layer?.shadowOffset = .zero
            contentView.layer?.shadowRadius = 8
            contentView.layer?.shadowOpacity = 0.5
            contentView.layer?.masksToBounds = false
        }

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            window.setFrame(frame, display: true)
            window.alphaValue = 1.0
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = SettingsStore.shared.animationDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(frame, display: true)
                window.animator().alphaValue = 1.0
            }
        }

        window.orderFront(nil)
    }

    func hide() {
        guard let window = previewWindow else { return }

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            window.alphaValue = 0.0
            previewWindow?.orderOut(nil)
        } else {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                window.animator().alphaValue = 0.0
            }, completionHandler: { [weak self] in
                self?.previewWindow?.orderOut(nil)
            })
        }
    }

    private func createWindow() {
        let window = NSWindow(
            contentRect: .zero,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.alphaValue = 0.0

        let contentView = NSView()
        contentView.wantsLayer = true

        // Subtle background blur for native feel
        let blurView = NSVisualEffectView()
        blurView.blendingMode = .behindWindow
        blurView.material = .hudWindow
        blurView.state = .active
        blurView.alphaValue = 0.3
        blurView.wantsLayer = true
        blurView.layer?.cornerRadius = 10
        blurView.layer?.masksToBounds = true
        blurView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(blurView)

        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: contentView.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        window.contentView = contentView

        previewWindow = window
    }
}
