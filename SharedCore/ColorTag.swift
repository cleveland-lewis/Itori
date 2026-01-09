import SwiftUI

public enum ColorTag: String, CaseIterable, Identifiable {
    case blue, green, purple, orange, pink, yellow, teal, red, indigo, mint, cyan, brown
    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .blue: Color(hue: 0.55, saturation: 0.70, brightness: 0.85)
        case .green: Color(hue: 0.35, saturation: 0.65, brightness: 0.75)
        case .purple: Color(hue: 0.75, saturation: 0.60, brightness: 0.80)
        case .orange: Color(hue: 0.10, saturation: 0.70, brightness: 0.85)
        case .pink: Color(hue: 0.95, saturation: 0.60, brightness: 0.85)
        case .yellow: Color(hue: 0.15, saturation: 0.65, brightness: 0.80)
        case .teal: Color(hue: 0.50, saturation: 0.60, brightness: 0.75)
        case .red: Color(hue: 0.00, saturation: 0.65, brightness: 0.80)
        case .indigo: Color(hue: 0.65, saturation: 0.65, brightness: 0.75)
        case .mint: Color(hue: 0.45, saturation: 0.55, brightness: 0.75)
        case .cyan: Color(hue: 0.52, saturation: 0.60, brightness: 0.80)
        case .brown: Color(hue: 0.08, saturation: 0.50, brightness: 0.65)
        }
    }
}
