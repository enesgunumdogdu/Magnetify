import SwiftUI

struct ShortcutsPane: View {

    @ObservedObject private var shortcutStore = ShortcutStore.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "settings.tab.shortcuts", defaultValue: "Shortcuts"))
                        .font(.system(size: 18, weight: .semibold))
                    Text(String(localized: "settings.shortcuts.subtitle", defaultValue: "Click any shortcut to change it. Toggle to enable or disable."))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    shortcutStore.resetToDefaults()
                } label: {
                    Text(String(localized: "settings.shortcuts.resetDefaults", defaultValue: "Reset to Defaults"))
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 10)

            // Shortcut list
            List {
                ForEach(SnapCategory.allCases) { category in
                    Section {
                        ForEach(category.positions) { position in
                            if let binding = shortcutStore.bindings.first(where: { $0.position == position }) {
                                shortcutRow(for: position, binding: binding)
                            }
                        }
                    } header: {
                        Text(category.displayName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }

    private func shortcutRow(for position: SnapPosition, binding: ShortcutBinding) -> some View {
        let hasConflict = binding.isEnabled && shortcutStore.hasConflict(for: binding)

        return HStack(spacing: 10) {
            Toggle(isOn: Binding(
                get: { binding.isEnabled },
                set: { newValue in
                    if let index = shortcutStore.bindings.firstIndex(where: { $0.id == binding.id }) {
                        shortcutStore.bindings[index].isEnabled = newValue
                    }
                }
            )) {
                HStack(spacing: 8) {
                    Image(systemName: position.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(.tint)
                        .frame(width: 18)
                    Text(position.displayName)
                        .font(.system(size: 13))
                }
            }

            Spacer()

            if hasConflict {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.yellow)
                    .help(String(localized: "settings.shortcuts.conflict", defaultValue: "Another shortcut uses this key combination"))
                    .accessibilityLabel(String(localized: "settings.shortcuts.conflict.accessibility", defaultValue: "Shortcut conflict"))
            }

            ShortcutRecorderView(
                binding: Binding(
                    get: { binding },
                    set: { newValue in
                        if let index = shortcutStore.bindings.firstIndex(where: { $0.id == binding.id }) {
                            shortcutStore.bindings[index] = newValue
                        }
                    }
                ),
                store: shortcutStore
            )
        }
        .padding(.vertical, 1)
    }
}
