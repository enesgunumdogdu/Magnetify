import SwiftUI

struct ProfilesPane: View {

    @ObservedObject private var profileStore = ProfileStore.shared
    @State private var showingNewProfileSheet = false
    @State private var newProfileName = ""
    @State private var selectedIcon = "rectangle.3.group"
    @State private var selectedApps: Set<String> = []

    private let iconOptions = [
        "rectangle.3.group", "laptopcomputer", "desktopcomputer",
        "doc.text", "pencil.and.ruler", "paintpalette",
        "terminal", "video", "music.note", "globe"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "settings.profiles.title", defaultValue: "Workspace Profiles"))
                        .font(.system(size: 18, weight: .semibold))
                    Text(String(localized: "settings.profiles.subtitle", defaultValue: "Save your current window arrangement and restore it anytime with one click."))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showingNewProfileSheet = true
                } label: {
                    Label(
                        String(localized: "settings.profiles.saveLayout", defaultValue: "Save Current Layout"),
                        systemImage: "plus"
                    )
                    .font(.system(size: 12))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 10)

            if profileStore.profiles.isEmpty {
                emptyState
            } else {
                profileList
            }
        }
        .sheet(isPresented: $showingNewProfileSheet) {
            newProfileSheet
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 40))
                .foregroundStyle(.quaternary)
            Text(String(localized: "settings.profiles.empty.title", defaultValue: "No Profiles Yet"))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            Text(String(
                localized: "settings.profiles.empty.description",
                defaultValue: "Save your current window layout to quickly restore it later."
            ))
            .font(.system(size: 12))
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 260)
            Button {
                showingNewProfileSheet = true
            } label: {
                Label(
                    String(localized: "settings.profiles.saveLayout", defaultValue: "Save Current Layout"),
                    systemImage: "plus"
                )
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var profileList: some View {
        List {
            ForEach(profileStore.profiles) { profile in
                profileRow(profile)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }

    private func profileRow(_ profile: WorkspaceProfile) -> some View {
        HStack(spacing: 12) {
            Image(systemName: profile.icon)
                .font(.system(size: 18))
                .foregroundStyle(.tint)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(profile.name)
                    .font(.system(size: 13, weight: .medium))
                HStack(spacing: 4) {
                    Text(String(localized: "settings.profiles.windowCount \(profile.windows.count)"))
                    if !profile.assignedApps.isEmpty {
                        Text("·")
                        Text(String(localized: "settings.profiles.appCount \(profile.assignedApps.count)"))
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                profileStore.applyProfile(profile)
            } label: {
                Text(String(localized: "settings.profiles.apply", defaultValue: "Apply"))
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Menu {
                Button {
                    recaptureProfile(profile)
                } label: {
                    Label(
                        String(localized: "settings.profiles.recapture", defaultValue: "Recapture Layout"),
                        systemImage: "arrow.clockwise"
                    )
                }
                Divider()
                Button(role: .destructive) {
                    profileStore.deleteProfile(id: profile.id)
                } label: {
                    Label(
                        String(localized: "settings.profiles.delete", defaultValue: "Delete"),
                        systemImage: "trash"
                    )
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
            .accessibilityLabel(String(localized: "accessibility.profiles.moreActions", defaultValue: "More actions"))
        }
        .padding(.vertical, 2)
    }

    private var newProfileSheet: some View {
        VStack(spacing: 16) {
            Text(String(localized: "settings.profiles.new.title", defaultValue: "Save Workspace Profile"))
                .font(.headline)

            TextField(
                String(localized: "settings.profiles.new.namePlaceholder", defaultValue: "Profile name"),
                text: $newProfileName
            )
            .textFieldStyle(.roundedBorder)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                ForEach(iconOptions, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedIcon == icon ? Color.accentColor.opacity(0.15) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedIcon == icon ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "accessibility.profiles.icon \(icon)"))
                    .accessibilityAddTraits(selectedIcon == icon ? [.isSelected] : [])
                }
            }

            appFilterSection

            HStack {
                Button(String(localized: "settings.profiles.new.cancel", defaultValue: "Cancel")) {
                    showingNewProfileSheet = false
                    newProfileName = ""
                    selectedApps = []
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(String(localized: "settings.profiles.new.save", defaultValue: "Save")) {
                    saveNewProfile()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 360)
    }

    private var appFilterSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "settings.profiles.new.filterApps", defaultValue: "Filter Apps (optional)"))
                .font(.caption)
                .foregroundStyle(.secondary)

            let runningApps = NSWorkspace.shared.runningApplications.filter {
                $0.activationPolicy == .regular && !$0.isTerminated && $0.bundleIdentifier != nil
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(runningApps, id: \.processIdentifier) { app in
                        if let bundleId = app.bundleIdentifier {
                            Toggle(isOn: Binding(
                                get: { selectedApps.contains(bundleId) },
                                set: { isOn in
                                    if isOn { selectedApps.insert(bundleId) }
                                    else { selectedApps.remove(bundleId) }
                                }
                            )) {
                                Text(app.localizedName ?? bundleId)
                                    .font(.callout)
                            }
                            .toggleStyle(.checkbox)
                        }
                    }
                }
            }
            .frame(maxHeight: 100)

            if selectedApps.isEmpty {
                Text(String(localized: "settings.profiles.new.allAppsHint", defaultValue: "No selection means all apps will be captured."))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func saveNewProfile() {
        let appsArray = Array(selectedApps)
        let windows = profileStore.captureCurrentLayout(filterApps: appsArray)
        let profile = WorkspaceProfile(name: newProfileName, icon: selectedIcon, windows: windows, assignedApps: appsArray)
        profileStore.addProfile(profile)
        newProfileName = ""
        selectedApps = []
        showingNewProfileSheet = false
    }

    private func recaptureProfile(_ profile: WorkspaceProfile) {
        let windows = profileStore.captureCurrentLayout()
        var updated = profile
        updated.windows = windows
        updated.updatedAt = Date()
        profileStore.updateProfile(updated)
    }
}
