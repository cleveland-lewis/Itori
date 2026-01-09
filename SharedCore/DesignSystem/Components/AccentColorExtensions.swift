import SwiftUI

#if os(macOS)
    import AppKit
#endif

// MARK: - Accent Color Application

extension View {
    /// Applies the centralized accent color to the view
    /// Use this for generic UI elements (buttons, toggles, segmented controls, etc.)
    func accentedUI() -> some View {
        self.tint(DesignSystem.Colors.accent)
    }

    /// Applies accent color with reduced opacity for hover states
    func accentedHover(opacity: Double = 0.15) -> some View {
        self.foregroundStyle(DesignSystem.Colors.accent)
            .background(DesignSystem.Colors.accent.opacity(opacity))
    }

    /// Applies accent color for selection highlights
    func accentedSelection(isSelected: Bool) -> some View {
        self.foregroundStyle(isSelected ? .white : .primary)
            .background(isSelected ? DesignSystem.Colors.accent : .clear)
    }
}

// MARK: - Semantic Color Preservation

extension View {
    /// Mark a view as using semantic colors (will not be affected by accent color changes)
    /// Use for: event colors, course colors, category colors, status indicators
    func semanticColor() -> some View {
        // This is a no-op modifier that serves as documentation
        // It indicates this view uses semantic colors intentionally
        self
    }
}
