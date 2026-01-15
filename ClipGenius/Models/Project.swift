import Foundation
import SwiftData
import SwiftUI

/// SwiftData model representing a project for organizing clips
@Model
final class Project {
    /// Unique identifier for this project
    var id: UUID
    
    /// Display name for the project
    var name: String
    
    /// Color accent for visual identification (hex string)
    var colorHex: String?
    
    /// Computed color property from hex string
    var color: Color? {
        get {
            guard let hex = colorHex else { return nil }
            return Color(hex: hex)
        }
        set {
            colorHex = newValue?.toHex()
        }
    }
    
    /// Creation date
    var createdAt: Date
    
    /// Last modification date
    var updatedAt: Date
    
    /// Clips belonging to this project
    @Relationship(deleteRule: .nullify)
    var clips: [ClipboardItem]?
    
    /// Designated initializer
    init(
        id: UUID = UUID(),
        name: String,
        color: Color? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = color?.toHex()
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Returns the count of clips in this project
    var clipCount: Int {
        clips?.count ?? 0
    }
}

/// Color extension for hex conversion
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
    
    func toHex() -> String? {
        #if os(macOS)
        guard let components = NSColor(self).usingColorSpace(.deviceRGB) else { return nil }
        let r = Int(components.redComponent * 255)
        let g = Int(components.greenComponent * 255)
        let b = Int(components.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
        #else
        return nil
        #endif
    }
}
