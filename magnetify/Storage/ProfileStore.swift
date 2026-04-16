import Foundation
import Combine
import AppKit
import os

final class ProfileStore: ObservableObject {

    static let shared = ProfileStore()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify",
        category: "ProfileStore"
    )

    @Published var profiles: [WorkspaceProfile] {
        didSet { save() }
    }

    private let storageKey = "workspaceProfiles"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([WorkspaceProfile].self, from: data) {
            self.profiles = decoded
        } else {
            self.profiles = []
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    // MARK: - CRUD

    func addProfile(_ profile: WorkspaceProfile) {
        profiles.append(profile)
        logger.info("Added workspace profile '\(profile.name)' with \(profile.windows.count) windows")
    }

    func deleteProfile(id: UUID) {
        profiles.removeAll { $0.id == id }
        logger.info("Deleted workspace profile")
    }

    func updateProfile(_ profile: WorkspaceProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            logger.info("Updated workspace profile '\(profile.name)'")
        }
    }

    // MARK: - Capture & Apply

    func captureCurrentLayout(filterApps: [String] = []) -> [WindowSnapshot] {
        var snapshots: [WindowSnapshot] = []

        let runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && !$0.isTerminated
        }

        for app in runningApps {
            guard let bundleId = app.bundleIdentifier else { continue }

            if !filterApps.isEmpty && !filterApps.contains(bundleId) {
                continue
            }
            let appElement = AXUIElementCreateApplication(app.processIdentifier)

            var windowsRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(
                appElement,
                kAXWindowsAttribute as CFString,
                &windowsRef
            ) == .success,
                  let windows = windowsRef as? [AXUIElement] else { continue }

            for window in windows {
                guard let frame = try? WindowAccessor.getWindowFrame(window) else { continue }

                // Skip very small windows (menus, popups)
                guard frame.width > 50 && frame.height > 50 else { continue }

                snapshots.append(WindowSnapshot(
                    bundleIdentifier: bundleId,
                    appName: app.localizedName ?? bundleId,
                    frame: frame
                ))
            }
        }

        logger.info("Captured \(snapshots.count) windows from current layout")
        return snapshots
    }

    func applyProfile(_ profile: WorkspaceProfile) {
        let runningApps = NSWorkspace.shared.runningApplications

        for snapshot in profile.windows {
            if !profile.assignedApps.isEmpty && !profile.assignedApps.contains(snapshot.bundleIdentifier) {
                continue
            }

            guard let app = runningApps.first(where: {
                $0.bundleIdentifier == snapshot.bundleIdentifier
            }), !app.isTerminated else { continue }

            let appElement = AXUIElementCreateApplication(app.processIdentifier)

            var windowsRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(
                appElement,
                kAXWindowsAttribute as CFString,
                &windowsRef
            ) == .success,
                  let windows = windowsRef as? [AXUIElement],
                  let window = windows.first else { continue }

            do {
                try WindowAccessor.setWindowFrame(window, frame: snapshot.frame.cgRect)
            } catch {
                logger.error("Failed to restore window for \(snapshot.appName): \(error.localizedDescription)")
            }
        }

        logger.info("Applied workspace profile '\(profile.name)'")
    }
}
