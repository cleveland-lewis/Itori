//
//  SemanticColors+macOS.swift
//  Itori
//
//  Semantic color mappings for HIG compliance
//  Created: 2026-01-03
//

#if os(macOS)
import SwiftUI

extension ShapeStyle where Self == Color {
    
    // MARK: - Background Colors
    
    /// Primary background color for main content areas
    static var primaryBackground: Color {
        Color(nsColor: .windowBackgroundColor)
    }
    
    /// Secondary background for cards, panels, sidebars
    static var secondaryBackground: Color {
        Color(nsColor: .controlBackgroundColor)
    }
    
    /// Tertiary background for nested content
    static var tertiaryBackground: Color {
        Color(nsColor: .textBackgroundColor)
    }
    
    /// Background for selected items
    static var selectedBackground: Color {
        Color(nsColor: .selectedContentBackgroundColor)
    }
    
    /// Subtle background for hover states
    static var hoverBackground: Color {
        Color(nsColor: .controlBackgroundColor)
    }
    
    // MARK: - Separator Colors
    
    /// Standard separator line color
    static var separatorColor: Color {
        Color(nsColor: .separatorColor)
    }
    
    // MARK: - Text Colors
    
    /// Primary text color (already exists as .primary)
    /// Secondary text color (already exists as .secondary)
    /// Tertiary text color (already exists as .tertiary)
    
    // MARK: - Accent Color Variants
    
    /// Very subtle accent background (5% opacity equivalent)
    static var accentQuinary: Color {
        Color.accentColor.opacity(0.05)
    }
    
    /// Subtle accent background (10% opacity equivalent)  
    static var accentQuaternary: Color {
        Color.accentColor.opacity(0.1)
    }
    
    /// Light accent background (20% opacity equivalent)
    static var accentTertiary: Color {
        Color.accentColor.opacity(0.2)
    }
    
    /// Medium accent background (40% opacity equivalent)
    static var accentSecondary: Color {
        Color.accentColor.opacity(0.4)
    }
}

// MARK: - Legacy Color Mapping (for gradual migration)

extension Color {
    
    /// Maps old NSColor usage to semantic colors
    static func semantic(for nsColor: NSColor) -> Color {
        switch nsColor {
        case .windowBackgroundColor:
            return .primaryBackground
        case .controlBackgroundColor:
            return .secondaryBackground
        case .textBackgroundColor:
            return .tertiaryBackground
        case .selectedContentBackgroundColor:
            return .selectedBackground
        case .separatorColor:
            return .separatorColor
        default:
            return Color(nsColor: nsColor)
        }
    }
}

#endif
