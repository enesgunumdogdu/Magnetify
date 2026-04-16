import Foundation
import Combine
import os

final class ShortcutStore: ObservableObject {

    static let shared = ShortcutStore()

    @Published var bindings: [ShortcutBinding] {
        didSet { save() }
    }

    private let storageKey = "shortcutBindings"
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify", category: "ShortcutStore")

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ShortcutBinding].self, from: data) {
            self.bindings = decoded
        } else {
            self.bindings = DefaultShortcuts.all()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(bindings) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func resetToDefaults() {
        bindings = DefaultShortcuts.all()
    }

    // MARK: - Conflict Detection

    /// Returns true if another enabled binding already uses the same keyCode and modifiers.
    func hasConflict(for binding: ShortcutBinding) -> Bool {
        bindings.contains { other in
            other.id != binding.id &&
            other.isEnabled &&
            other.keyCode == binding.keyCode &&
            other.modifiers == binding.modifiers
        }
    }

    /// Returns all bindings that conflict with the given binding (same keyCode + modifiers, different id).
    func conflictingBindings(for binding: ShortcutBinding) -> [ShortcutBinding] {
        bindings.filter { other in
            other.id != binding.id &&
            other.isEnabled &&
            other.keyCode == binding.keyCode &&
            other.modifiers == binding.modifiers
        }
    }
}
