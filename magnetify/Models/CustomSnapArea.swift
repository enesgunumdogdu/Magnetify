import CoreGraphics
import Foundation

struct CustomSnapArea: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var rect: CodableRect

    init(name: String, rect: CodableRect) {
        self.id = UUID()
        self.name = name
        self.rect = rect
    }

    func absoluteFrame(on screenFrame: CGRect) -> CGRect {
        CGRect(
            x: screenFrame.origin.x + rect.x * screenFrame.width,
            y: screenFrame.origin.y + rect.y * screenFrame.height,
            width: rect.width * screenFrame.width,
            height: rect.height * screenFrame.height
        )
    }
}
