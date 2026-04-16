import SwiftUI
import Carbon
import os

struct ShortcutRecorderView: View {

    @Binding var binding: ShortcutBinding
    @ObservedObject var store: ShortcutStore

    @State private var isRecording = false
    @State private var isHovering = false
    @State private var conflictMessage: String?
    @State private var eventMonitor: Any?
    @State private var pulseAnimation = false

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify",
        category: "ShortcutRecorderView"
    )

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            badgeView
                .onTapGesture {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }
                .onHover { hovering in
                    isHovering = hovering
                }
                .help(String(localized: "shortcuts.recorder.tooltip", defaultValue: "Click to change shortcut"))
                .accessibilityLabel(
                    isRecording
                        ? String(localized: "shortcuts.recorder.recording.accessibility", defaultValue: "Recording shortcut. Press a key combination or Escape to cancel.")
                        : String(localized: "shortcuts.recorder.accessibility", defaultValue: "Shortcut: \(binding.displayString). Click to change.")
                )

            if let conflict = conflictMessage {
                Text(conflict)
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: conflictMessage != nil)
        .onDisappear {
            cleanUpMonitor()
        }
    }

    @ViewBuilder
    private var badgeView: some View {
        if isRecording {
            recordingBadge
        } else {
            normalBadge
        }
    }

    private var normalBadge: some View {
        Text(binding.displayString)
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(binding.isEnabled ? .primary : .tertiary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(.quaternary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(isHovering ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
    }

    private var recordingBadge: some View {
        Text(String(localized: "shortcuts.recorder.prompt", defaultValue: "Type shortcut..."))
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(.quaternary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(
                        conflictMessage != nil ? Color.red : Color.accentColor,
                        lineWidth: pulseAnimation ? 2 : 1
                    )
                    .animation(
                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
            )
            .onAppear {
                pulseAnimation = true
            }
            .onDisappear {
                pulseAnimation = false
            }
    }

    // MARK: - Recording

    private func startRecording() {
        guard eventMonitor == nil else { return }
        isRecording = true
        conflictMessage = nil

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyEvent(event)
            return nil // consume the event
        }

        logger.debug("Started shortcut recording for position: \(binding.position.rawValue)")
    }

    private func stopRecording() {
        isRecording = false
        pulseAnimation = false
        cleanUpMonitor()
    }

    private func cleanUpMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        // Escape cancels recording
        if event.keyCode == 0x35 {
            conflictMessage = nil
            stopRecording()
            return
        }

        // Ignore modifier-only key presses
        let keyCode = UInt32(event.keyCode)
        guard KeyCodeMapping.name(for: keyCode) != nil else {
            return
        }

        // Build Carbon modifier mask
        let flags = event.modifierFlags
        var modifiers: UInt32 = 0

        if flags.contains(.control) {
            modifiers |= UInt32(controlKey)
        }
        if flags.contains(.option) {
            modifiers |= UInt32(optionKey)
        }
        if flags.contains(.shift) {
            modifiers |= UInt32(shiftKey)
        }
        if flags.contains(.command) {
            modifiers |= UInt32(cmdKey)
        }

        // Require at least one modifier (except for F-keys)
        let isFunctionKey = (0x7A...0x7F).contains(keyCode) ||
                            (0x60...0x6F).contains(keyCode)
        if modifiers == 0 && !isFunctionKey {
            return
        }

        // Build a temporary binding to check conflicts
        var candidateBinding = binding
        candidateBinding.keyCode = keyCode
        candidateBinding.modifiers = modifiers

        let conflicts = store.conflictingBindings(for: candidateBinding)
        if !conflicts.isEmpty {
            let conflictName = conflicts.first?.position.displayName ?? ""
            conflictMessage = String(
                localized: "shortcuts.recorder.conflict",
                defaultValue: "Conflicts with \(conflictName)"
            )
            logger.info("Shortcut conflict detected with \(conflictName)")
            return
        }

        // No conflict — apply the new shortcut
        if let index = store.bindings.firstIndex(where: { $0.id == binding.id }) {
            store.bindings[index].keyCode = keyCode
            store.bindings[index].modifiers = modifiers
        }

        conflictMessage = nil
        stopRecording()
        logger.info("Shortcut updated for \(binding.position.rawValue): keyCode=\(keyCode), modifiers=\(modifiers)")
    }
}
