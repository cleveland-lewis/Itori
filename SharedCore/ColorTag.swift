import SwiftUI

public enum ColorTag: String, CaseIterable, Identifiable {
    case blue, green, purple, orange, pink, yellow, teal, red, indigo, mint, cyan, brown
    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .blue: return Color(hue: 0.55, saturation: 0.70, brightness: 0.85)
        case .green: return Color(hue: 0.35, saturation: 0.65, brightness: 0.75)
        case .purple: return Color(hue: 0.75, saturation: 0.60, brightness: 0.80)
        case .orange: return Color(hue: 0.10, saturation: 0.70, brightness: 0.85)
        case .pink: return Color(hue: 0.95, saturation: 0.60, brightness: 0.85)
        case .yellow: return Color(hue: 0.15, saturation: 0.65, brightness: 0.80)
        case .teal: return Color(hue: 0.50, saturation: 0.60, brightness: 0.75)
        case .red: return Color(hue: 0.00, saturation: 0.65, brightness: 0.80)
        case .indigo: return Color(hue: 0.65, saturation: 0.65, brightness: 0.75)
        case .mint: return Color(hue: 0.45, saturation: 0.55, brightness: 0.75)
        case .cyan: return Color(hue: 0.52, saturation: 0.60, brightness: 0.80)
        case .brown: return Color(hue: 0.08, saturation: 0.50, brightness: 0.65)
        }
    }
}

