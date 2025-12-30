import SwiftUI

// MARK: - Animation Helpers

extension View {
    /// Apply animation from preferences (automatically nil if reduce motion is enabled)
    func prefsAnimation(_ animation: AnimationStyle = .standard) -> some View {
        modifier(PreferencesAnimationModifier(style: animation))
    }
}

enum AnimationStyle {
    case quick
    case standard
    case deliberate
    case spring
}

private struct PreferencesAnimationModifier: ViewModifier {
    @Environment(\.interfacePreferences) private var prefs
    let style: AnimationStyle
    
    func body(content: Content) -> some View {
        let animation: Animation? = {
            switch style {
            case .quick: return prefs.animation.quick
            case .standard: return prefs.animation.standard
            case .deliberate: return prefs.animation.deliberate
            case .spring: return prefs.animation.spring
            }
        }()
        
        return content.animation(animation, value: UUID())
    }
}

// MARK: - Spacing Helpers

extension View {
    /// Apply card padding from preferences
    func prefsCardPadding() -> some View {
        modifier(PreferencesCardPaddingModifier())
    }
    
    /// Apply custom spacing from preferences
    func prefsPadding(_ edges: Edge.Set = .all, _ token: PreferencesSpacingToken) -> some View {
        modifier(PreferencesSpacingModifier(edges: edges, token: token))
    }
    
    /// Apply list row insets from preferences
    func prefsListRowInsets() -> some View {
        modifier(PreferencesListRowInsetsModifier())
    }
}

enum PreferencesSpacingToken {
    case xxs, xs, sm, md, lg, xl, xxl, xxxl
    case cardPadding
    case sectionSpacing
    case gridGap
}

private struct PreferencesCardPaddingModifier: ViewModifier {
    @Environment(\.interfacePreferences) private var prefs
    
    func body(content: Content) -> some View {
        content.padding(prefs.spacing.cardPadding)
    }
}

private struct PreferencesSpacingModifier: ViewModifier {
    @Environment(\.interfacePreferences) private var prefs
    let edges: Edge.Set
    let token: PreferencesSpacingToken
    
    func body(content: Content) -> some View {
        let value: CGFloat = {
            switch token {
            case .xxs: return prefs.spacing.xxs
            case .xs: return prefs.spacing.xs
            case .sm: return prefs.spacing.sm
            case .md: return prefs.spacing.md
            case .lg: return prefs.spacing.lg
            case .xl: return prefs.spacing.xl
            case .xxl: return prefs.spacing.xxl
            case .xxxl: return prefs.spacing.xxxl
            case .cardPadding: return prefs.spacing.cardPadding
            case .sectionSpacing: return prefs.spacing.sectionSpacing
            case .gridGap: return prefs.spacing.gridGap
            }
        }()
        
        return content.padding(edges, value)
    }
}

private struct PreferencesListRowInsetsModifier: ViewModifier {
    @Environment(\.interfacePreferences) private var prefs
    
    func body(content: Content) -> some View {
        content.listRowInsets(EdgeInsets(
            top: prefs.spacing.listRowVerticalPadding,
            leading: prefs.spacing.listRowHorizontalPadding,
            bottom: prefs.spacing.listRowVerticalPadding,
            trailing: prefs.spacing.listRowHorizontalPadding
        ))
    }
}

// MARK: - Material Helpers

extension View {
    /// Apply card material from preferences
    func prefsCardMaterial(cornerRadius: CGFloat? = nil) -> some View {
        modifier(PreferencesCardMaterialModifier(cornerRadius: cornerRadius))
    }
    
    /// Apply HUD material from preferences
    func prefsHUDMaterial(cornerRadius: CGFloat? = nil) -> some View {
        modifier(PreferencesHUDMaterialModifier(cornerRadius: cornerRadius))
    }
    
    /// Apply popup material from preferences
    func prefsPopupMaterial(cornerRadius: CGFloat? = nil) -> some View {
        modifier(PreferencesPopupMaterialModifier(cornerRadius: cornerRadius))
    }
    
    /// Apply overlay material from preferences
    func prefsOverlayMaterial(cornerRadius: CGFloat? = nil) -> some View {
        modifier(PreferencesOverlayMaterialModifier(cornerRadius: cornerRadius))
    }
    
    /// Apply border from preferences
    func prefsBorder(cornerRadius: CGFloat? = nil, color: Color? = nil) -> some View {
        modifier(PreferencesBorderModifier(cornerRadius: cornerRadius, color: color))
    }
}

private struct PreferencesCardMaterialModifier: ViewModifier {
    @Environment(\.interfacePreferences) private var prefs
    let cornerRadius: CGFloat?
    
    func body(content: Content) -> some View {
        let radius = cornerRadius ?? prefs.cornerRadius.card
        
        return Group {
            switch prefs.materials.cardMaterial {
            case .material(let material):
                content.background(material, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            case .solid(let color):
                content.background(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(color)
                )
            }
        }
    }
}

private struct PreferencesHUDMaterialModifier: ViewModifier {
    @Environment(\.interfacePreferences) private var prefs
    let cornerRadius: CGFloat?
    
    func body(content: Content) -> some View {
        let radius = cornerRadius ?? prefs.cornerRadius.medium
        
        return Group {
            switch prefs.materials.hudMaterial {
            case .material(let material):
                content.background(material, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            case .solid(let color):
                content.background(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(color)
                )
            }
        }
    }
}

private struct PreferencesPopupMaterialModifier: ViewModifier {
    @Environment(\.interfacePreferences) private var prefs
    let cornerRadius: CGFloat?
    
    func body(content: Content) -> some View {
        let radius = cornerRadius ?? prefs.cornerRadius.large
        
        return Group {
            switch prefs.materials.popupMaterial {
            case .material(let material):
                content.background(material, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            case .solid(let color):
                content.background(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(color)
                )
            }
        }
    }
}

private struct PreferencesOverlayMaterialModifier: ViewModifier {
    @Environment(\.interfacePreferences) private var prefs
    let cornerRadius: CGFloat?
    
    func body(content: Content) -> some View {
        let radius = cornerRadius ?? prefs.cornerRadius.medium
        
        return Group {
            switch prefs.materials.overlayMaterial {
            case .material(let material):
                content.background(material, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            case .solid(let color):
                content.background(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(color)
                )
            }
        }
    }
}

private struct PreferencesBorderModifier: ViewModifier {
    @Environment(\.interfacePreferences) private var prefs
    let cornerRadius: CGFloat?
    let color: Color?
    
    func body(content: Content) -> some View {
        let radius = cornerRadius ?? prefs.cornerRadius.card
        let borderColor = color ?? Color.primary
        
        return content.overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(borderColor.opacity(prefs.materials.borderOpacity), lineWidth: prefs.materials.borderWidth)
        )
    }
}

// MARK: - Corner Radius Helpers

extension View {
    /// Apply corner radius from preferences
    func prefsCornerRadius(_ style: PreferencesCornerRadiusStyle = .card) -> some View {
        modifier(PreferencesCornerRadiusModifier(style: style))
    }
}

enum PreferencesCornerRadiusStyle {
    case small, medium, large, xlarge, card, button, field
}

private struct PreferencesCornerRadiusModifier: ViewModifier {
    @Environment(\.interfacePreferences) private var prefs
    let style: PreferencesCornerRadiusStyle
    
    func body(content: Content) -> some View {
        let radius: CGFloat = {
            switch style {
            case .small: return prefs.cornerRadius.small
            case .medium: return prefs.cornerRadius.medium
            case .large: return prefs.cornerRadius.large
            case .xlarge: return prefs.cornerRadius.xlarge
            case .card: return prefs.cornerRadius.card
            case .button: return prefs.cornerRadius.button
            case .field: return prefs.cornerRadius.field
            }
        }()
        
        return content.clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

// MARK: - Haptics Helpers

#if os(iOS)
import UIKit

extension View {
    /// Trigger haptic feedback (respects preferences)
    func prefsHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light, trigger: some Equatable) -> some View {
        modifier(PreferencesHapticModifier(style: style, trigger: trigger))
    }
}

private struct PreferencesHapticModifier<T: Equatable>: ViewModifier {
    @Environment(\.interfacePreferences) private var prefs
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    let trigger: T
    
    func body(content: Content) -> some View {
        content.onChange(of: trigger) { _, _ in
            if prefs.haptics.enabled {
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.impactOccurred()
            }
        }
    }
}
#endif
