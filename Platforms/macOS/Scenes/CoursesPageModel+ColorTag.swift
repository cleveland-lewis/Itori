#if os(macOS)
import SwiftUI

extension ColorTag {
    static func fromHex(_ hex: String?) -> ColorTag? {
        guard let hex = hex?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else { return nil }
        switch hex {
        case "#4c78ff", "blue": return .blue
        case "#34c759", "green": return .green
        case "#af52de", "purple": return .purple
        case "#ff9f0a", "orange": return .orange
        case "#ff2d55", "pink": return .pink
        case "#ffd60a", "yellow": return .yellow
        case "#40e0d0", "teal": return .teal
        case "#e74c3c", "red": return .red
        case "#5c6bc0", "indigo": return .indigo
        case "#98d8c8", "mint": return .mint
        case "#00ced1", "cyan": return .cyan
        case "#a0826d", "brown": return .brown
        case "#8e8e93", "gray": return .brown // Map gray to brown
        default: return nil
        }
    }

    static func hex(for tag: ColorTag) -> String {
        switch tag {
        case .blue: return "#4C78FF"
        case .green: return "#34C759"
        case .purple: return "#AF52DE"
        case .orange: return "#FF9F0A"
        case .pink: return "#FF2D55"
        case .yellow: return "#FFD60A"
        case .teal: return "#40E0D0"
        case .red: return "#E74C3C"
        case .indigo: return "#5C6BC0"
        case .mint: return "#98D8C8"
        case .cyan: return "#00CED1"
        case .brown: return "#A0826D"
        }
    }
}

#endif
