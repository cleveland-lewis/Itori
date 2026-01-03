import SwiftUI

/// A standardized sidebar card style matching the design used in Calendar
/// Provides consistent material, corner radius, and border across all sidebars
struct SidebarCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DesignSystem.Materials.card)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusStandard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusStandard, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

extension View {
    /// Applies the standard sidebar card styling (material, rounded corners, border)
    func sidebarCardStyle() -> some View {
        modifier(SidebarCardStyle())
    }
}
