import SwiftUI

// MARK: - Colors (semantic)
enum RootsColor {
    static var backgroundPrimary: Color { Color(nsColor: .windowBackgroundColor) }
    static var cardBackground: Color { Color(nsColor: .controlBackgroundColor) }
    static var glassBorder: Color { Color(nsColor: .separatorColor) }
    static var accent: Color { .accentColor }
    static var textPrimary: Color { .primary }
    static var textSecondary: Color { .secondary }
    static var label: Color { .primary }
    static var secondaryLabel: Color { .secondary }
    static var subtleFill: Color { Color.primary.opacity(0.06) }
}

// MARK: - Spacing
// Note: RootsSpacing is defined in Roots/DesignTokensCompat.swift to avoid redeclaration

// MARK: - Radius
// Note: RootsRadius is defined in Roots/DesignTokensCompat.swift to avoid redeclaration

// MARK: - Shadows
extension View {
    func rootsCardShadow() -> some View {
        shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
    }

    func rootsFloatingShadow() -> some View {
        shadow(color: Color.primary.opacity(0.12), radius: 20, y: 10)
    }
}

// MARK: - Typography
extension Text {
    func rootsTitle() -> some View { font(.system(size: 22, weight: .semibold)).applyPopupTextAlignment() }
    func rootsSectionHeader() -> some View { font(.system(size: 14, weight: .semibold)).applyPopupTextAlignment() }
    func rootsBody() -> some View { font(.system(size: 13, weight: .regular)).applyPopupTextAlignment() }
    func rootsBodySecondary() -> some View { font(.system(size: 13)).foregroundColor(.secondary).applyPopupTextAlignment() }
    func rootsCaption() -> some View { font(.footnote).foregroundColor(.secondary).applyPopupTextAlignment() }
    func rootsMono() -> some View { font(.system(.body, design: .monospaced)).applyPopupTextAlignment() }
}

// MARK: - Glass / Background helpers
extension View {
    func rootsGlassBackground(opacity: Double = 0.2, radius: CGFloat = RootsRadius.card) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(DesignSystem.Materials.card)
                .opacity(opacity)
        )
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    func rootsCardBackground(radius: CGFloat = RootsRadius.card) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(DesignSystem.Materials.card)
        )
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
