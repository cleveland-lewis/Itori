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
            case .blue: "#4C78FF"
            case .green: "#34C759"
            case .purple: "#AF52DE"
            case .orange: "#FF9F0A"
            case .pink: "#FF2D55"
            case .yellow: "#FFD60A"
            case .teal: "#40E0D0"
            case .red: "#E74C3C"
            case .indigo: "#5C6BC0"
            case .mint: "#98D8C8"
            case .cyan: "#00CED1"
            case .brown: "#A0826D"
            }
        }
    }

#endif
