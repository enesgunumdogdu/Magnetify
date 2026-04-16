import AppKit
import Foundation
import Combine
import os

final class CustomSnapAreaStore: ObservableObject {
    static let shared = CustomSnapAreaStore()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify", category: "CustomSnapArea")

    @Published var areas: [CustomSnapArea] {
        didSet { save() }
    }

    private let storageKey = "customSnapAreas"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([CustomSnapArea].self, from: data) {
            self.areas = decoded
        } else {
            self.areas = []
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(areas) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func addArea(_ area: CustomSnapArea) {
        areas.append(area)
    }

    func deleteArea(id: UUID) {
        areas.removeAll { $0.id == id }
    }

    func updateArea(_ area: CustomSnapArea) {
        if let index = areas.firstIndex(where: { $0.id == area.id }) {
            areas[index] = area
        }
    }

    func snapToArea(_ area: CustomSnapArea) {
        guard let screen = NSScreen.main else { return }
        let frame = area.absoluteFrame(on: screen.visibleFrame)

        guard let window = try? WindowAccessor.getFocusedWindow() else { return }
        do {
            try WindowAccessor.setWindowFrame(window, frame: frame)
            logger.info("Snapped to custom area '\(area.name)'")
        } catch {
            logger.error("Failed to snap to custom area: \(error.localizedDescription)")
        }
    }
}
