import Foundation
import Carbon
import Combine

final class ShortcutManager: ObservableObject {

    @Published var bindings: [ShortcutBinding] = []

    private var hotKeyRefs: [EventHotKeyRef] = []
    private var hotkeyMap: [UInt32: SnapPosition] = [:]
    private var eventHandlerRef: EventHandlerRef?
    private var onSnap: ((SnapPosition) -> Void)?
    var onChainMode: (() -> Void)?
    private var eventHandlerInstalled = false

    private static var instance: ShortcutManager?

    init() {
        ShortcutManager.instance = self
    }

    func configure(onSnap: @escaping (SnapPosition) -> Void) {
        self.onSnap = onSnap
    }

    func registerAll() {
        unregisterAll()

        var counter: UInt32 = 0
        for binding in bindings where binding.isEnabled {
            register(binding: binding, id: counter)
            hotkeyMap[counter] = binding.position
            counter += 1
        }

        installEventHandler()
    }

    func registerChainModeHotkey() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D47_4E46), id: 9999)
        var hotKeyRef: EventHotKeyRef?
        RegisterEventHotKey(
            0x31,
            UInt32(controlKey) | UInt32(optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if let ref = hotKeyRef {
            hotKeyRefs.append(ref)
        }
    }

    func unregisterAll() {
        for ref in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        hotkeyMap.removeAll()

        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
            eventHandlerInstalled = false
        }
    }

    private func register(binding: ShortcutBinding, id: UInt32) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D47_4E46), id: id) // "MGNF"

        let carbonModifiers = carbonModifierFlags(from: binding.modifiers)

        let status = RegisterEventHotKey(
            binding.keyCode,
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs.append(ref)
        }
    }

    private func installEventHandler() {
        guard !eventHandlerInstalled else { return }
        eventHandlerInstalled = true

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                ShortcutManager.handleHotKeyEvent(event)
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )
    }

    private static func handleHotKeyEvent(_ event: EventRef?) -> OSStatus {
        guard let event = event else { return OSStatus(eventNotHandledErr) }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            UInt32(kEventParamDirectObject),
            UInt32(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr else { return status }

        guard let manager = instance else { return OSStatus(eventNotHandledErr) }

        if hotKeyID.id == 9999 {
            manager.onChainMode?()
            return noErr
        }

        guard let position = manager.hotkeyMap[hotKeyID.id] else {
            return OSStatus(eventNotHandledErr)
        }

        manager.onSnap?(position)

        return noErr
    }

    private func carbonModifierFlags(from flags: UInt32) -> UInt32 {
        var carbonFlags: UInt32 = 0

        if flags & UInt32(controlKey) != 0 {
            carbonFlags |= UInt32(controlKey)
        }
        if flags & UInt32(optionKey) != 0 {
            carbonFlags |= UInt32(optionKey)
        }
        if flags & UInt32(shiftKey) != 0 {
            carbonFlags |= UInt32(shiftKey)
        }
        if flags & UInt32(cmdKey) != 0 {
            carbonFlags |= UInt32(cmdKey)
        }

        return carbonFlags
    }

    deinit {
        unregisterAll()
    }
}
