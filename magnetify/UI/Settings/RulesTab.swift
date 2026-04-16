import SwiftUI

struct RulesPane: View {

    @ObservedObject private var store = RuleStore.shared
    @State private var showingAppPicker = false
    @State private var selectedApp: NSRunningApplication?
    @State private var selectedPosition: SnapPosition = .leftHalf

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "settings.rules.title", defaultValue: "App Rules"))
                        .font(.system(size: 18, weight: .semibold))
                    Text(String(localized: "settings.rules.subtitle", defaultValue: "Automatically position app windows when they launch. Add a rule to get started."))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showingAppPicker = true
                } label: {
                    Label(
                        String(localized: "settings.rules.add", defaultValue: "Add Rule"),
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

            if store.rules.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "app.badge.checkmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.quaternary)
                    Text(String(localized: "settings.rules.empty.title", defaultValue: "No Rules Yet"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(String(localized: "settings.rules.empty.description", defaultValue: "No rules yet. Add a rule to automatically snap an app's window to a specific position when it launches."))
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 260)
                    Button {
                        showingAppPicker = true
                    } label: {
                        Label(
                            String(localized: "settings.rules.add", defaultValue: "Add Rule"),
                            systemImage: "plus"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(store.rules) { rule in
                        ruleRow(rule)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .sheet(isPresented: $showingAppPicker) {
            appPickerSheet
        }
    }

    private func ruleRow(_ rule: AppRule) -> some View {
        HStack(spacing: 10) {
            Toggle(isOn: Binding(
                get: { rule.isEnabled },
                set: { newValue in
                    var updated = rule
                    updated.isEnabled = newValue
                    store.updateRule(updated)
                }
            )) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(rule.appName)
                        .font(.system(size: 13, weight: .medium))
                    Text(rule.bundleIdentifier)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Picker("", selection: Binding(
                get: { rule.position },
                set: { newPosition in
                    var updated = rule
                    updated.position = newPosition
                    store.updateRule(updated)
                }
            )) {
                ForEach(SnapPosition.allCases.filter { $0 != .restore && $0 != .moveToNextScreen && $0 != .moveToPreviousScreen }) { position in
                    Label(position.displayName, systemImage: position.icon).tag(position)
                }
            }
            .frame(width: 150)
            .accessibilityLabel(String(localized: "accessibility.rules.position \(rule.appName)"))

            Button(role: .destructive) {
                store.deleteRule(id: rule.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .accessibilityLabel(String(localized: "accessibility.rules.delete \(rule.appName)"))
        }
        .padding(.vertical, 2)
    }

    private var appPickerSheet: some View {
        VStack(spacing: 16) {
            Text(String(localized: "settings.rules.new.title", defaultValue: "Add App Rule"))
                .font(.headline)

            List(runningApps, id: \.processIdentifier, selection: $selectedApp) { app in
                HStack(spacing: 8) {
                    if let icon = app.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    Text(app.localizedName ?? app.bundleIdentifier ?? String(localized: "settings.rules.new.unknownApp", defaultValue: "Unknown"))
                        .font(.system(size: 13))
                }
                .tag(app)
            }
            .frame(height: 180)
            .listStyle(.inset)

            Picker(String(localized: "settings.rules.new.position", defaultValue: "Snap Position"), selection: $selectedPosition) {
                ForEach(SnapPosition.allCases.filter { $0 != .restore && $0 != .moveToNextScreen && $0 != .moveToPreviousScreen }) { position in
                    Label(position.displayName, systemImage: position.icon).tag(position)
                }
            }

            HStack {
                Button(String(localized: "settings.rules.new.cancel", defaultValue: "Cancel")) {
                    showingAppPicker = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(String(localized: "settings.rules.new.save", defaultValue: "Add")) {
                    if let app = selectedApp, let bundleId = app.bundleIdentifier {
                        let rule = AppRule(
                            bundleIdentifier: bundleId,
                            appName: app.localizedName ?? bundleId,
                            position: selectedPosition
                        )
                        store.addRule(rule)
                    }
                    showingAppPicker = false
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(selectedApp == nil)
            }
        }
        .padding(20)
        .frame(width: 380, height: 360)
    }

    private var runningApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && !$0.isTerminated && $0.bundleIdentifier != nil }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }
}
