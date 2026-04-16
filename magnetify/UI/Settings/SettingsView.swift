import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case snapping
    case appearance
    case shortcuts
    case profiles
    case rules
    case snapAreas
    case about

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .general: return String(localized: "settings.tab.general", defaultValue: "General")
        case .snapping: return String(localized: "settings.tab.snapping", defaultValue: "Snapping")
        case .appearance: return String(localized: "settings.tab.appearance", defaultValue: "Appearance")
        case .shortcuts: return String(localized: "settings.tab.shortcuts", defaultValue: "Shortcuts")
        case .profiles: return String(localized: "settings.tab.profiles", defaultValue: "Profiles")
        case .rules: return String(localized: "settings.tab.rules", defaultValue: "Rules")
        case .snapAreas: return String(localized: "settings.tab.snapAreas", defaultValue: "Snap Areas")
        case .about: return String(localized: "settings.tab.about", defaultValue: "About")
        }
    }

    var icon: String {
        switch self {
        case .general: return "gear"
        case .snapping: return "rectangle.split.2x2"
        case .appearance: return "paintbrush"
        case .shortcuts: return "keyboard"
        case .profiles: return "rectangle.3.group"
        case .rules: return "app.badge.checkmark"
        case .snapAreas: return "rectangle.dashed"
        case .about: return "info.circle"
        }
    }

    var color: Color {
        switch self {
        case .general: return .gray
        case .snapping: return .orange
        case .appearance: return .pink
        case .shortcuts: return .blue
        case .profiles: return .teal
        case .rules: return .green
        case .snapAreas: return .indigo
        case .about: return .gray
        }
    }

    enum Group: String, CaseIterable {
        case settings
        case features
        case other
    }

    var group: Group {
        switch self {
        case .general, .snapping, .appearance: return .settings
        case .shortcuts, .profiles, .rules, .snapAreas: return .features
        case .about: return .other
        }
    }

    static func sections(for group: Group) -> [SettingsSection] {
        allCases.filter { $0.group == group }
    }
}

struct SettingsView: View {

    @State private var selectedSection: SettingsSection = .general

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 200)
                .background(.ultraThinMaterial)

            Divider()

            detailPane
                .id(selectedSection)
                .transition(.opacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primary.opacity(0.02))
        }
        .frame(width: 780, height: 560)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: Binding(
            get: { selectedSection },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedSection = newValue
                }
            }
        )) {
            Section {
                ForEach(SettingsSection.sections(for: .settings)) { section in
                    sidebarRow(section)
                }
            } header: {
                Text(String(localized: "settings.sidebar.general", defaultValue: "SETTINGS"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.horizontal, 8)

            Section {
                ForEach(SettingsSection.sections(for: .features)) { section in
                    sidebarRow(section)
                }
            } header: {
                Text(String(localized: "settings.sidebar.features", defaultValue: "FEATURES"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Section {
                ForEach(SettingsSection.sections(for: .other)) { section in
                    sidebarRow(section)
                }
            }
        }
        .listStyle(.sidebar)
        .accessibilityLabel(String(localized: "accessibility.settings.sidebar", defaultValue: "Settings navigation"))
    }

    private func sidebarRow(_ section: SettingsSection) -> some View {
        let isSelected = selectedSection == section

        return Label {
            Text(section.displayName)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
        } icon: {
            Image(systemName: section.icon)
                .font(.system(size: 11))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(section.color.gradient)
                )
                .shadow(color: section.color.opacity(0.3), radius: 2, y: 1)
        }
        .tag(section)
        .listRowBackground(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [section.color, section.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.horizontal, 2)
                } else {
                    Color.clear
                }
            }
        )
        .accessibilityLabel(section.displayName)
    }

    // MARK: - Detail Pane

    @ViewBuilder
    private var detailPane: some View {
        switch selectedSection {
        case .general:
            GeneralPane()
        case .snapping:
            SnappingPane()
        case .appearance:
            AppearancePane()
        case .shortcuts:
            ShortcutsPane()
        case .profiles:
            ProfilesPane()
        case .rules:
            RulesPane()
        case .snapAreas:
            SnapAreasPane()
        case .about:
            AboutPane()
        }
    }
}
