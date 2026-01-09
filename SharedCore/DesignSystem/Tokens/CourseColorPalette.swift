import SwiftUI

/// Stable, accessible color palette for courses and categories
enum CourseColorPalette {
    /// Predefined palette optimized for readability in both light and dark modes
    static let palette: [Color] = [
        // Blues
        Color(hue: 0.55, saturation: 0.70, brightness: 0.85), // Sky blue
        Color(hue: 0.60, saturation: 0.65, brightness: 0.75), // Teal

        // Purples
        Color(hue: 0.75, saturation: 0.60, brightness: 0.80), // Lavender
        Color(hue: 0.80, saturation: 0.55, brightness: 0.75), // Purple

        // Greens
        Color(hue: 0.35, saturation: 0.65, brightness: 0.75), // Green
        Color(hue: 0.40, saturation: 0.60, brightness: 0.70), // Mint

        // Oranges/Yellows
        Color(hue: 0.10, saturation: 0.70, brightness: 0.85), // Orange
        Color(hue: 0.15, saturation: 0.65, brightness: 0.80), // Amber

        // Reds/Pinks
        Color(hue: 0.95, saturation: 0.60, brightness: 0.85), // Pink
        Color(hue: 0.00, saturation: 0.65, brightness: 0.80), // Red

        // Additional variety
        Color(hue: 0.50, saturation: 0.55, brightness: 0.75), // Cyan
        Color(hue: 0.85, saturation: 0.50, brightness: 0.80) // Magenta
    ]

    /// Get a stable color for a course based on its ID
    /// - Parameters:
    ///   - courseID: UUID of the course
    ///   - colorHex: Optional custom color hex string
    /// - Returns: Color for the course
    static func color(for courseID: UUID, colorHex: String? = nil) -> Color {
        // Prefer custom color if available
        if let hex = colorHex, let customColor = Color(hex: hex) {
            return customColor
        }

        // Use deterministic palette selection based on UUID
        let index = abs(courseID.hashValue) % palette.count
        return palette[index]
    }

    /// Get a stable color for a course name (fallback when UUID unavailable)
    /// - Parameter name: Course name or identifier
    /// - Returns: Color from palette
    static func color(for name: String) -> Color {
        var hash = 5381
        for c in name.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(c.value)
        }
        let index = abs(hash) % palette.count
        return palette[index]
    }
}

// Extension to make courses use the palette
extension Course {
    var stableColor: Color {
        CourseColorPalette.color(for: id, colorHex: colorHex)
    }
}
