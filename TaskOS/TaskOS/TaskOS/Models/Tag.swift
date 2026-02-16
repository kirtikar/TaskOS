import Foundation
import SwiftData
import SwiftUI

// MARK: - Tag

@Model
final class Tag {
    var id: UUID
    var name: String
    var colorName: String
    var createdAt: Date

    @Relationship(inverse: \Task.tags)
    var tasks: [Task]

    var color: Color {
        Color(hex: colorName) ?? .blue
    }

    init(name: String, color: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.colorName = color
        self.createdAt = Date()
        self.tasks = []
    }
}

// MARK: - Color Hex Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let r = Int((components[0]) * 255)
        let g = Int((components[1]) * 255)
        let b = Int((components[2]) * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
