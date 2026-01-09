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
        let animation: Animation? = switch style {
        case .quick: prefs.animation.quick
        case .standard: prefs.animation.standard
        case .deliberate: prefs.animation.deliberate
        case .spring: prefs.animation.spring
        }

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
        let value: CGFloat = switch token {
        case .xxs: prefs.spacing.xxs
        case .xs: prefs.spacing.xs
        case .sm: prefs.spacing.sm
        case .md: prefs.spacing.md
        case .lg: prefs.spacing.lg
        case .xl: prefs.spacing.xl
        case .xxl: prefs.spacing.xxl
        case .xxxl: prefs.spacing.xxxl
        case .cardPadding: prefs.spacing.cardPadding
        case .sectionSpacing: prefs.spacing.sectionSpacing
        case .gridGap: prefs.spacing.gridGap
        }

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
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat?

    func body(content: Content) -> some View {
        let radius = cornerRadius ?? prefs.cornerRadius.card
        let depthTint = colorScheme == .dark
            ? Color.white.opacity(0.04)
            : Color.black.opacity(0.04)

        return Group {
            switch prefs.materials.cardMaterial {
            case let .material(material):
                content.background(material, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            case let .solid(color):
                content.background(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(color)
                )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(depthTint)
        )
    }
}

private struct PreferencesHUDMaterialModifier: ViewModifier {
    @Environment(\.interfacePreferences) private var prefs
    let cornerRadius: CGFloat?

    func body(content: Content) -> some View {
        let radius = cornerRadius ?? prefs.cornerRadius.medium

        return Group {
            switch prefs.materials.hudMaterial {
            case let .material(material):
                content.background(material, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            case let .solid(color):
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
            case let .material(material):
                content.background(material, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            case let .solid(color):
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
            case let .material(material):
                content.background(material, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            case let .solid(color):
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
        let radius: CGFloat = switch style {
        case .small: prefs.cornerRadius.small
        case .medium: prefs.cornerRadius.medium
        case .large: prefs.cornerRadius.large
        case .xlarge: prefs.cornerRadius.xlarge
        case .card: prefs.cornerRadius.card
        case .button: prefs.cornerRadius.button
        case .field: prefs.cornerRadius.field
        }

        return content.clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

// MARK: - Haptics Helpers

#if os(iOS)
    import UIKit

    extension View {
        /// Trigger haptic feedback (respects preferences)
        func prefsHapticFeedback(
            _ style: UIImpactFeedbackGenerator.FeedbackStyle = .light,
            trigger: some Equatable
        ) -> some View {
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
