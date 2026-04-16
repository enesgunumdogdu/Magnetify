import Foundation
import AppKit
import Combine
import os

final class SizeTemplateStore: ObservableObject {
    static let shared = SizeTemplateStore()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.magnetify", category: "SizeTemplate")

    @Published var templates: [SizeTemplate] {
        didSet { save() }
    }

    private let storageKey = "sizeTemplates"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([SizeTemplate].self, from: data) {
            self.templates = decoded
        } else {
            self.templates = SizeTemplate.defaults
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func addTemplate(_ template: SizeTemplate) { templates.append(template) }
    func deleteTemplate(id: UUID) { templates.removeAll { $0.id == id } }
    func updateTemplate(_ template: SizeTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        }
    }

    func applyTemplate(_ template: SizeTemplate) {
        guard let screen = NSScreen.main,
              let window = try? WindowAccessor.getFocusedWindow() else { return }

        let size = template.absoluteSize(on: screen)

        do {
            if template.centerOnScreen {
                let frame = CGRect(
                    x: screen.visibleFrame.midX - size.width / 2,
                    y: screen.visibleFrame.midY - size.height / 2,
                    width: size.width,
                    height: size.height
                )
                try WindowAccessor.setWindowFrame(window, frame: frame)
            } else {
                try WindowAccessor.setWindowSize(window, size: size)
            }
            logger.info("Applied size template '\(template.name)'")
        } catch {
            logger.error("Failed to apply size template: \(error.localizedDescription)")
        }
    }

    func resetToDefaults() {
        templates = SizeTemplate.defaults
    }
}
