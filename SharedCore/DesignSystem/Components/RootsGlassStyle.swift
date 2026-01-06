import SwiftUI

enum RootsGlassStyle {
    static var cardCornerRadius: CGFloat { 16 }
    static var chromeCornerRadius: CGFloat { 12 }

    #if os(macOS)
    static var cardShadow: Color { Color.clear }
    static var chromeShadow: Color { Color.clear }
    #else
    static var cardShadow: Color { Color.black.opacity(0.18) }
    static var chromeShadow: Color { Color.black.opacity(0.12) }
    #endif
}

struct GlassCardModifier: ViewModifier {
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var settings: AppSettingsModel
    @Environment(\.colorScheme) private var colorScheme
    
    var cornerRadius: CGFloat
    
    private var resolvedCornerRadius: CGFloat {
        let baseRadius = RootsGlassStyle.cardCornerRadius
        let preferredRadius = CGFloat(settings.cardCornerRadius)
        guard baseRadius > 0 else { return cornerRadius }
        let scale = preferredRadius / baseRadius
        return max(2, cornerRadius * scale)
    }

    private var surfaceTint: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.025)
    }
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .background(
                RoundedRectangle(cornerRadius: resolvedCornerRadius, style: .continuous)
                    .fill(DesignSystem.Materials.card)
                    .opacity(DesignSystem.Materials.cardOpacity)
            )
            .overlay(
                RoundedRectangle(cornerRadius: resolvedCornerRadius, style: .continuous)
                    .fill(surfaceTint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: resolvedCornerRadius, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 1)
            )
        #else
        let policy = MaterialPolicy(
            reduceTransparency: preferences.reduceTransparency || !settings.enableGlassEffects,
            increaseContrast: preferences.highContrast,
            differentiateWithoutColor: false
        )

        content
            .background(
                RoundedRectangle(cornerRadius: resolvedCornerRadius, style: .continuous)
                    .fill(policy.cardMaterial(colorScheme: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: resolvedCornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(policy.borderOpacity), lineWidth: policy.borderWidth)
            )
            .shadow(color: RootsGlassStyle.cardShadow, radius: 8, x: 0, y: 4)
        #endif
    }
}

extension View {
    /// Glass card surface (for Dashboard cards, metrics, panels, popups).
    func glassCard(cornerRadius: CGFloat = RootsGlassStyle.cardCornerRadius) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    /// Glass chrome surface (for tab bars, chips, navigation chrome).
    func glassChrome(cornerRadius: CGFloat = RootsGlassStyle.chromeCornerRadius) -> some View {
        self.modifier(GlassChromeModifier(cornerRadius: cornerRadius))
    }
}

struct GlassChromeModifier: ViewModifier {
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var settings: AppSettingsModel
    @Environment(\.colorScheme) private var colorScheme
    
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(DesignSystem.Colors.sidebarBackground)
            )
        #else
        let policy = MaterialPolicy(
            reduceTransparency: preferences.reduceTransparency || !settings.enableGlassEffects,
            increaseContrast: preferences.highContrast,
            differentiateWithoutColor: false
        )

        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(policy.hudMaterial(colorScheme: colorScheme))
            )
            .shadow(color: RootsGlassStyle.chromeShadow, radius: 6, x: 0, y: 2)
        #endif
    }
}
