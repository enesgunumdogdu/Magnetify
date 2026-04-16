import SwiftUI

struct SnapButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SnapGridView: View {

    let onSnap: (SnapPosition) -> Void
    let onCycle: () -> Void
    let onQuit: () -> Void
    let onSettings: () -> Void

    @State private var hoveredPosition: SnapPosition? = nil
    @State private var hoveredCustomArea: UUID? = nil
    @State private var hoveredProfile: UUID? = nil
    @State private var hoveredTemplate: UUID? = nil
    @State private var hoveredLayout: GroupSnapManager.QuickLayout? = nil
    @State private var hoveredFooter: FooterButton? = nil
    @State private var lastUsedPosition: SnapPosition? = nil

    private enum FooterButton {
        case cycle, settings, quit
    }

    var body: some View {
        VStack(spacing: 12) {
            headerSection

            Divider()
                .padding(.vertical, 2)

            ForEach(SnapCategory.allCases) { category in
                snapCategorySection(category)
            }

            if !CustomSnapAreaStore.shared.areas.isEmpty {
                Divider()
                    .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader(
                        String(localized: "menubar.customAreas", defaultValue: "Custom Areas")
                    )

                    ForEach(CustomSnapAreaStore.shared.areas) { area in
                        Button {
                            CustomSnapAreaStore.shared.snapToArea(area)
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.dashed")
                                Text(area.name)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(hoveredCustomArea == area.id ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                        .onHover { isHovering in
                            hoveredCustomArea = isHovering ? area.id : nil
                        }
                        .accessibilityHint(String(localized: "accessibility.menubar.customArea.hint", defaultValue: "Double-tap to snap to this area"))
                    }
                }
            }

            if !ProfileStore.shared.profiles.isEmpty {
                Divider()
                    .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader(
                        String(localized: "menubar.profiles", defaultValue: "Profiles")
                    )

                    ForEach(ProfileStore.shared.profiles) { profile in
                        Button {
                            ProfileStore.shared.applyProfile(profile)
                        } label: {
                            HStack {
                                Image(systemName: profile.icon)
                                Text(profile.name)
                                Spacer()
                                Text("\(profile.windows.count)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(hoveredProfile == profile.id ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                        .onHover { isHovering in
                            hoveredProfile = isHovering ? profile.id : nil
                        }
                        .accessibilityHint(String(localized: "accessibility.menubar.profile.hint", defaultValue: "Double-tap to apply this profile"))
                    }
                }
            }

            if !SizeTemplateStore.shared.templates.isEmpty {
                Divider()
                    .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader(
                        String(localized: "menubar.sizeTemplates", defaultValue: "Size Templates")
                    )

                    ForEach(SizeTemplateStore.shared.templates) { template in
                        Button {
                            SizeTemplateStore.shared.applyTemplate(template)
                        } label: {
                            HStack {
                                Image(systemName: "aspectratio")
                                Text(template.name)
                                Spacer()
                                Text(template.unit == .pixels ? "\(Int(template.width))×\(Int(template.height))" : "\(Int(template.width))%×\(Int(template.height))%")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(hoveredTemplate == template.id ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                        .onHover { isHovering in
                            hoveredTemplate = isHovering ? template.id : nil
                        }
                        .accessibilityHint(String(localized: "accessibility.menubar.template.hint", defaultValue: "Double-tap to apply this size template"))
                    }
                }
            }

            Divider()
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 6) {
                sectionHeader(
                    String(localized: "menubar.quickLayouts", defaultValue: "Quick Layouts")
                )

                ForEach(GroupSnapManager.QuickLayout.allCases, id: \.self) { layout in
                    Button {
                        let windows = GroupSnapManager.shared.getVisibleWindows()
                        GroupSnapManager.shared.snapWindows(Array(windows.prefix(layout.positions.count)), to: layout.positions)
                    } label: {
                        HStack {
                            Image(systemName: layout.icon)
                            Text(layout.displayName)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(hoveredLayout == layout ? Color.accentColor.opacity(0.15) : Color.clear)
                    )
                    .onHover { isHovering in
                        hoveredLayout = isHovering ? layout : nil
                    }
                    .accessibilityHint(String(localized: "accessibility.menubar.quickLayout.hint", defaultValue: "Double-tap to arrange windows in this layout"))
                }
            }

            Divider()
                .padding(.vertical, 2)

            footerSection
        }
        .padding(12)
        .frame(width: 280)
        .background(.ultraThickMaterial)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 6) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 16, height: 16)
            Text(String(localized: "menubar.title", defaultValue: "Magnetify"))
                .font(.headline.weight(.semibold))
            Spacer()
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    // MARK: - Snap Grid

    private func categoryAccentColor(_ category: SnapCategory) -> Color {
        switch category {
        case .halves: return .green
        case .quarters: return .orange
        case .thirds: return .purple
        case .twoThirds: return .indigo
        case .monitor: return .blue
        case .other: return .teal
        }
    }

    private func snapCategorySection(_ category: SnapCategory) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 3) {
                sectionHeader(category.displayName)
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(categoryAccentColor(category).opacity(0.5))
                    .frame(width: 24, height: 1.5)
            }

            LazyVGrid(columns: gridColumns(for: category), spacing: 4) {
                ForEach(category.positions) { position in
                    snapButton(for: position)
                }
            }
        }
    }

    private func gridColumns(for category: SnapCategory) -> [GridItem] {
        let count: Int
        switch category {
        case .halves: count = 4
        case .quarters: count = 4
        case .thirds: count = 3
        case .twoThirds: count = 2
        case .monitor: count = 2
        case .other: count = 2
        }
        return Array(repeating: GridItem(.flexible(), spacing: 4), count: count)
    }

    private func snapButton(for position: SnapPosition) -> some View {
        let isHovered = hoveredPosition == position
        let isLastUsed = lastUsedPosition == position

        return Button {
            lastUsedPosition = position
            onSnap(position)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: position.icon)
                    .font(.system(size: 18))
                Text(position.displayName)
                    .font(.system(size: 9))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(SnapButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    isHovered
                        ? AnyShapeStyle(Color.accentColor.opacity(0.15))
                        : AnyShapeStyle(
                            LinearGradient(
                                colors: [Color.primary.opacity(0.07), Color.primary.opacity(0.03)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    isLastUsed ? Color.accentColor.opacity(0.6) : Color.primary.opacity(0.12),
                    lineWidth: isLastUsed ? 1.5 : 0.5
                )
        )
        .shadow(color: .primary.opacity(0.04), radius: 1, y: 1)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { isHovering in
            hoveredPosition = isHovering ? position : nil
        }
        .help(position.displayName)
        .accessibilityLabel(position.displayName)
        .accessibilityHint(String(localized: "accessibility.snapButton.hint", defaultValue: "Double-tap to snap the frontmost window"))
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            footerButton(
                title: String(localized: "menubar.cycle", defaultValue: "Next Position in Category"),
                icon: "arrow.triangle.2.circlepath",
                type: .cycle,
                action: onCycle
            )

            Spacer()

            footerButton(
                title: String(localized: "menubar.settings", defaultValue: "Settings..."),
                icon: "gear",
                type: .settings,
                shortcutHint: "\u{2318},",
                action: onSettings
            )

            Spacer()

            footerButton(
                title: String(localized: "menubar.quit", defaultValue: "Quit Magnetify"),
                icon: "power",
                type: .quit,
                shortcutHint: "\u{2318}Q",
                action: onQuit
            )
        }
        .font(.caption)
    }

    private func footerButton(
        title: String,
        icon: String,
        type: FooterButton,
        shortcutHint: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        let isHovered = hoveredFooter == type

        return Button {
            action()
        } label: {
            HStack(spacing: 3) {
                Label(title, systemImage: icon)
                if let hint = shortcutHint {
                    Text(hint)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(
            type == .quit && isHovered ? AnyShapeStyle(.red.opacity(0.8)) :
            type == .quit ? AnyShapeStyle(.secondary) :
            isHovered ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary)
        )
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.accentColor.opacity(0.10) : Color.clear)
        )
        .onHover { isHovering in
            hoveredFooter = isHovering ? type : nil
        }
        .help(title)
    }
}
