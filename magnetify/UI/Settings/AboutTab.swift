import SwiftUI

struct AboutPane: View {

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 128, height: 128)
                .shadow(color: .accentColor.opacity(0.3), radius: 20, y: 8)

            Spacer().frame(height: 20)

            // App name
            Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Magnetify")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Spacer().frame(height: 6)

            // Version
            Text(
                String(localized: "about.version", defaultValue: "Version") +
                " \(appVersion)"
            )
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundStyle(.secondary)

            Spacer().frame(height: 12)

            // Description
            Text(String(localized: "about.description", defaultValue: "A powerful window manager for macOS"))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 28)

            // Feature badges
            HStack(spacing: 12) {
                featureBadge(
                    icon: "hand.draw",
                    label: String(localized: "about.feature.drag", defaultValue: "Drag & Snap")
                )
                featureBadge(
                    icon: "keyboard",
                    label: String(localized: "about.feature.keys", defaultValue: "Shortcuts")
                )
                featureBadge(
                    icon: "rectangle.3.group",
                    label: String(localized: "about.feature.profiles", defaultValue: "Profiles")
                )
                featureBadge(
                    icon: "display.2",
                    label: String(localized: "about.feature.multiMonitor", defaultValue: "Multi-Monitor")
                )
            }

            Spacer()

            // Support links
            HStack(spacing: 16) {
                Link(String(localized: "about.support", defaultValue: "Support"),
                     destination: URL(string: "https://example.com/contact")!)

                Link(String(localized: "about.privacy", defaultValue: "Privacy Policy"),
                     destination: URL(string: "https://example.com/privacy")!)

                Link(String(localized: "about.terms", defaultValue: "Terms of Use"),
                     destination: URL(string: "https://example.com/terms")!)
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)

            Spacer().frame(height: 12)

            // Copyright
            Text(String(localized: "about.copyright", defaultValue: "© 2026 Magnetify. All rights reserved."))
                .font(.system(size: 10))
                .foregroundStyle(.quaternary)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func featureBadge(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.tint)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.tint.opacity(0.1))
                )
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}
