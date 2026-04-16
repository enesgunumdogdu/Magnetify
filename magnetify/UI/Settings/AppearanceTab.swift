import SwiftUI

struct AppearancePane: View {

    @ObservedObject private var settings = SettingsStore.shared
    @State private var selectedColor: Color = .blue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader(
                    String(localized: "settings.tab.appearance", defaultValue: "Appearance"),
                    subtitle: String(localized: "settings.appearance.subtitle", defaultValue: "Customize the visual preview that appears when snapping windows")
                )

                // Preview card
                previewCard
                    .accessibilityHidden(true)

                Text(String(localized: "settings.appearance.section.animation", defaultValue: "Animation"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 4)

                settingsGroup {
                    sliderRow(
                        icon: "hare",
                        iconColor: .orange,
                        title: String(localized: "settings.appearance.animationSpeed", defaultValue: "Animation speed"),
                        value: $settings.animationDuration,
                        range: 0...0.5,
                        step: 0.05,
                        unit: String(localized: "settings.appearance.seconds", defaultValue: "s"),
                        displayValue: String(format: "%.2f", settings.animationDuration)
                    )
                }

                Text(String(localized: "settings.appearance.section.preview", defaultValue: "Snap Preview"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 4)

                settingsGroup {
                    HStack(spacing: 12) {
                        iconBadge("paintpalette", color: .pink)

                        Text(String(localized: "settings.appearance.previewColor", defaultValue: "Preview color"))
                            .font(.system(size: 13))

                        Spacer()

                        ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                            .labelsHidden()
                            .accessibilityLabel(String(localized: "settings.appearance.previewColor", defaultValue: "Preview color"))
                            .onChange(of: selectedColor) { newValue in
                                settings.previewColorHex = NSColor(newValue).hexString
                            }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)

                    Divider().padding(.leading, 36)

                    sliderRow(
                        icon: "circle.lefthalf.filled",
                        iconColor: .gray,
                        title: String(localized: "settings.appearance.previewOpacity", defaultValue: "Preview opacity"),
                        value: $settings.previewOpacity,
                        range: 0.1...0.8,
                        step: 0.05,
                        unit: String(localized: "accessibility.unit.percent", defaultValue: "%"),
                        displayValue: "\(Int(settings.previewOpacity * 100))"
                    )
                }
            }
            .padding(.bottom, 16)
        }
        .onAppear {
            selectedColor = Color(nsColor: settings.previewColor)
        }
    }

    private var previewCard: some View {
        HStack(spacing: 0) {
            // Mini screen mockup showing the snap preview
            // RTL note: offsets below are intentionally fixed (not flipped) because
            // they represent physical screen positions in a decorative mockup.
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
                    .frame(width: 160, height: 96)

                // Simulated snap preview zone
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedColor.opacity(settings.previewOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(selectedColor.opacity(0.6), lineWidth: 2)
                    )
                    .frame(width: 76, height: 88)
                    .offset(x: -40)

                // Fake window
                RoundedRectangle(cornerRadius: 4)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .frame(width: 64, height: 48)
                    .offset(x: 24, y: 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
    }
}
