import SwiftUI
import os

struct GeneralPane: View {

    @ObservedObject private var settings = SettingsStore.shared
    @State private var showRestartAlert = false

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify", category: "GeneralPane")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader(
                    String(localized: "settings.tab.general", defaultValue: "General"),
                    subtitle: String(localized: "settings.general.subtitle", defaultValue: "Startup, menu bar, and window behavior")
                )

                settingsGroup {
                        toggleRow(
                            icon: "power",
                            iconColor: .green,
                            title: String(localized: "settings.general.launchAtLogin", defaultValue: "Launch at login"),
                            subtitle: String(localized: "settings.general.launchAtLogin.description", defaultValue: "Automatically start Magnetify when you log in"),
                            isOn: $settings.launchAtLogin
                        )

                        Divider().padding(.leading, 36)

                        toggleRow(
                            icon: "menubar.rectangle",
                            iconColor: .blue,
                            title: String(localized: "settings.general.showMenuBarIcon", defaultValue: "Show menu bar icon"),
                            subtitle: String(localized: "settings.general.showMenuBarIcon.description", defaultValue: "Display the Magnetify icon in the menu bar"),
                            isOn: $settings.showMenuBarIcon
                        )

                        Divider().padding(.leading, 36)

                        toggleRow(
                            icon: "memories",
                            iconColor: .purple,
                            title: String(localized: "settings.general.enableWindowMemory", defaultValue: "Remember window positions"),
                            subtitle: String(localized: "settings.general.enableWindowMemory.description", defaultValue: "Restore window positions when apps relaunch"),
                            isOn: $settings.enableWindowMemory
                        )
                    }

                    Text(String(localized: "settings.general.section.language", defaultValue: "Language"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 4)

                    settingsGroup {
                        languageRow
                    }

                    if StageManagerDetector.shared.isStageManagerEnabled {
                        HStack(spacing: 8) {
                            Image(systemName: "sidebar.squares.leading")
                                .foregroundStyle(.orange)
                            Text(String(localized: "settings.general.stageManager", defaultValue: "Stage Manager is active. Left edge snap zone is adjusted automatically."))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
            }
            .padding(.bottom, 16)
        }
        .alert(
            String(localized: "settings.language.restartTitle", defaultValue: "Restart Required"),
            isPresented: $showRestartAlert
        ) {
            Button(String(localized: "settings.language.restartNow", defaultValue: "Restart Now")) {
                restartApp()
            }
            Button(String(localized: "settings.language.restartLater", defaultValue: "Later"), role: .cancel) {}
        } message: {
            Text(String(localized: "settings.language.restartMessage", defaultValue: "Magnetify needs to restart to apply the language change."))
        }
    }

    // MARK: - Language Row

    private var languageRow: some View {
        HStack(spacing: 12) {
            iconBadge("globe", color: .cyan)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(String(localized: "settings.general.language", defaultValue: "App language"))
                    .font(.system(size: 13))
                Text(String(localized: "settings.general.language.description", defaultValue: "Override system language for Magnetify"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("", selection: $settings.appLanguage) {
                Text(String(localized: "settings.language.system", defaultValue: "System Default"))
                    .tag("")

                Divider()

                ForEach(AppLanguage.supported, id: \.code) { lang in
                    Text(lang.localName)
                        .tag(lang.code)
                }
            }
            .labelsHidden()
            .frame(width: 180)
            .onChange(of: settings.appLanguage) { newValue in
                applyLanguage(newValue)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Language Helpers

    private func applyLanguage(_ code: String) {
        if code.isEmpty {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        }
        logger.info("App language changed to: \(code.isEmpty ? "system" : code)")
        showRestartAlert = true
    }

    private func restartApp() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        NSApp.terminate(nil)
    }
}

// MARK: - Supported Languages

struct AppLanguage {
    let code: String
    let localName: String

    static let supported: [AppLanguage] = {
        let codes = [
            "ar", "ca", "cs", "da", "de", "el", "en", "es", "fi", "fr",
            "he", "hi", "hr", "hu", "id", "it", "ja", "ko", "ms", "nb",
            "nl", "pl", "pt", "ro", "ru", "sk", "sv", "th", "tr", "uk",
            "vi", "zh-Hans", "zh-Hant"
        ]
        return codes.compactMap { code in
            let locale = Locale(identifier: code)
            guard let name = locale.localizedString(forIdentifier: code) else { return nil }
            return AppLanguage(code: code, localName: name.prefix(1).uppercased() + name.dropFirst())
        }.sorted { $0.localName.localizedCompare($1.localName) == .orderedAscending }
    }()
}

// MARK: - Snapping Pane

struct SnappingPane: View {

    @ObservedObject private var settings = SettingsStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                String(localized: "settings.tab.snapping", defaultValue: "Snapping"),
                subtitle: String(localized: "settings.snapping.subtitle", defaultValue: "Configure how windows snap to positions")
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    settingsGroup {
                    toggleRow(
                        icon: "hand.draw",
                        iconColor: .orange,
                        title: String(localized: "settings.general.enableDragToSnap", defaultValue: "Enable drag to snap"),
                        subtitle: String(localized: "settings.snapping.drag.description", defaultValue: "Drag windows to screen edges to snap them"),
                        isOn: $settings.enableDragToSnap
                    )

                    Divider().padding(.leading, 36)

                    toggleRow(
                        icon: "keyboard",
                        iconColor: .blue,
                        title: String(localized: "settings.general.enableKeyboardShortcuts", defaultValue: "Enable keyboard shortcuts"),
                        subtitle: String(localized: "settings.snapping.keyboard.description", defaultValue: "Use keyboard combinations for quick snapping"),
                        isOn: $settings.enableKeyboardShortcuts
                    )

                    Divider().padding(.leading, 36)

                    toggleRow(
                        icon: "circle.fill",
                        iconColor: .green,
                        title: String(localized: "settings.general.enableGreenButtonSnap", defaultValue: "Show snap menu on zoom button"),
                        subtitle: String(localized: "settings.snapping.greenButton.description", defaultValue: "Right-click the green button to see snap options"),
                        isOn: $settings.enableGreenButtonSnap
                    )
                }

                Text(String(localized: "settings.general.section.layout", defaultValue: "Layout"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 4)

                settingsGroup {
                    sliderRow(
                        icon: "space",
                        iconColor: .indigo,
                        title: String(localized: "settings.general.gap", defaultValue: "Gap between windows"),
                        subtitle: String(localized: "settings.general.gap.description", defaultValue: "Space in pixels between snapped windows and screen edges"),
                        value: $settings.snapGap,
                        range: 0...20,
                        step: 1,
                        unit: String(localized: "settings.general.gapUnit", defaultValue: "px"),
                        displayValue: "\(Int(settings.snapGap))"
                    )

                    Divider().padding(.leading, 36)

                    sliderRow(
                        icon: "target",
                        iconColor: .red,
                        title: String(localized: "settings.general.sensitivity", defaultValue: "Edge trigger distance"),
                        subtitle: String(localized: "settings.general.sensitivity.description", defaultValue: "How close to the screen edge a window must be dragged to trigger snapping"),
                        value: $settings.snapSensitivity,
                        range: 1...20,
                        step: 1,
                        unit: String(localized: "settings.general.sensitivityUnit", defaultValue: "px"),
                        displayValue: "\(Int(settings.snapSensitivity))"
                    )
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }
}
