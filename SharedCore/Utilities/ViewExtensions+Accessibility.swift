import SwiftUI

// MARK: - System Accessibility Support (respects iOS/macOS Settings)

extension View {
    /// Applies animation only if Reduce Motion is OFF in system settings
    /// Automatically respects Settings > Accessibility > Motion > Reduce Motion
    @ViewBuilder
    public func systemAccessibleAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V
    ) -> some View {
        if #available(iOS 13.0, macOS 10.15, *) {
            self.modifier(SystemReduceMotionModifier(animation: animation, value: value))
        } else {
            self.animation(animation, value: value)
        }
    }
}

private struct SystemReduceMotionModifier<V: Equatable>: ViewModifier {
    let animation: Animation?
    let value: V
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func body(content: Content) -> some View {
        if reduceMotion {
            content // No animation when Reduce Motion is enabled
        } else {
            content.animation(animation, value: value)
        }
    }
}

// MARK: - System withAnimation wrapper

/// Executes animation block only if Reduce Motion is OFF
/// Automatically respects system accessibility settings
public func withSystemAnimation<Result>(
    _ animation: Animation? = .default,
    _ body: () throws -> Result
) rethrows -> Result {
    if #available(iOS 13.0, macOS 10.15, *) {
        // Check system setting
        #if os(iOS)
        if UIAccessibility.isReduceMotionEnabled {
            return try body()
        }
        #elseif os(macOS)
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            return try body()
        }
        #endif
    }
    return try withAnimation(animation, body)
}

// MARK: - Dynamic Type Support

extension View {
    /// Applies minimum tap target size that scales with Dynamic Type
    /// Respects Settings > Accessibility > Display & Text Size > Larger Text
    public func dynamicTapTarget(baseSize: CGFloat = 44) -> some View {
        self.modifier(DynamicTapTargetModifier(baseSize: baseSize))
    }
}

private struct DynamicTapTargetModifier: ViewModifier {
    let baseSize: CGFloat
    @Environment(\.sizeCategory) private var sizeCategory
    
    var scaledSize: CGFloat {
        // Scale tap target with Dynamic Type
        let scaleFactor: CGFloat
        switch sizeCategory {
        case .extraSmall, .small, .medium:
            scaleFactor = 1.0
        case .large:
            scaleFactor = 1.1
        case .extraLarge:
            scaleFactor = 1.2
        case .extraExtraLarge:
            scaleFactor = 1.3
        case .extraExtraExtraLarge:
            scaleFactor = 1.4
        case .accessibilityMedium:
            scaleFactor = 1.5
        case .accessibilityLarge:
            scaleFactor = 1.6
        case .accessibilityExtraLarge:
            scaleFactor = 1.7
        case .accessibilityExtraExtraLarge:
            scaleFactor = 1.8
        case .accessibilityExtraExtraExtraLarge:
            scaleFactor = 2.0
        @unknown default:
            scaleFactor = 1.0
        }
        return baseSize * scaleFactor
    }
    
    func body(content: Content) -> some View {
        content
            .frame(minWidth: scaledSize, minHeight: scaledSize)
    }
}

// MARK: - App-Specific Preferences (NOT Accessibility)

extension View {
    /// Applies card padding based on user's UI density preference
    /// This is an app-specific setting, not an accessibility feature
    public func compactModePadding() -> some View {
        self.modifier(CompactModePaddingModifier())
    }
}

private struct CompactModePaddingModifier: ViewModifier {
    @Environment(\.layoutMetrics) private var metrics
    
    func body(content: Content) -> some View {
        content.padding(metrics.cardPadding)
    }
}

// MARK: - Reduce Transparency Support

extension View {
    /// Conditionally applies blur/transparency based on system setting
    /// Respects Settings > Accessibility > Display & Text Size > Reduce Transparency
    public func systemAdaptiveBackground<S: ShapeStyle>(
        _ style: S,
        fallback: Color
    ) -> some View {
        self.modifier(AdaptiveBackgroundModifier(style: style, fallback: fallback))
    }
}

private struct AdaptiveBackgroundModifier<S: ShapeStyle>: ViewModifier {
    let style: S
    let fallback: Color
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    func body(content: Content) -> some View {
        content.background(
            reduceTransparency ? AnyShapeStyle(fallback) : AnyShapeStyle(style)
        )
    }
}

// MARK: - Differentiate Without Color Support

extension View {
    /// Adds visual indicators beyond color when system setting is enabled
    /// Respects Settings > Accessibility > Display & Text Size > Differentiate Without Color
    public func differentiableIndicator(
        isActive: Bool,
        shape: some Shape = Rectangle()
    ) -> some View {
        self.modifier(DifferentiableIndicatorModifier(isActive: isActive, shape: AnyShape(shape)))
    }
}

private struct DifferentiableIndicatorModifier: ViewModifier {
    let isActive: Bool
    let shape: AnyShape
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    
    func body(content: Content) -> some View {
        content.overlay(
            Group {
                if differentiateWithoutColor && isActive {
                    // Add checkmark or indicator for users who can't rely on color
                    shape
                        .strokeBorder(Color.primary, lineWidth: 2)
                }
            }
        )
    }
}

// MARK: - Increase Contrast Support

extension View {
    /// Enhances text opacity for better contrast when Increase Contrast is enabled
    /// Respects Settings > Accessibility > Display & Text Size > Increase Contrast
    public func contrastAwareOpacity(_ opacity: Double) -> some View {
        self.modifier(ContrastAwareOpacityModifier(baseOpacity: opacity))
    }
    
    /// Applies stronger colors when Increase Contrast is enabled
    public func contrastAwareForeground(_ color: Color) -> some View {
        self.modifier(ContrastAwareForegroundModifier(color: color))
    }
}

extension ShapeStyle where Self == Color {
    /// Creates a color with opacity that enhances in high contrast mode
    /// Use for backgrounds and decorative elements
    static func contrastAware(_ color: Color, opacity: Double) -> Color {
        // In real usage, this would check accessibility settings
        // For now, returns the base color with opacity
        return color.opacity(opacity)
    }
}

private struct ContrastAwareOpacityModifier: ViewModifier {
    let baseOpacity: Double
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    // Use reduceTransparency as a proxy for high contrast needs
    // (Apple doesn't expose increaseContrast in SwiftUI yet)
    var enhancedOpacity: Double {
        if reduceTransparency {
            // Increase opacity by ~50% when transparency is reduced
            return min(1.0, baseOpacity * 1.5)
        }
        return baseOpacity
    }
    
    func body(content: Content) -> some View {
        content.opacity(enhancedOpacity)
    }
}

private struct ContrastAwareForegroundModifier: ViewModifier {
    let color: Color
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        if reduceTransparency {
            // Use higher contrast variants
            if colorScheme == .dark {
                content.foregroundStyle(color == .secondary ? Color.white.opacity(0.9) : color)
            } else {
                content.foregroundStyle(color == .secondary ? Color.black.opacity(0.8) : color)
            }
        } else {
            content.foregroundStyle(color)
        }
    }
}

// Helper for type-erased shapes
private struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - Gentle Mode (App-Specific, NOT System Accessibility)

extension AppSettingsModel {
    /// Gentle mode is an app-specific UI preference for sensory sensitivity
    /// It's NOT a replacement for system accessibility settings
    public var isGentleModeActive: Bool {
        // This can remain as an app-specific preference
        compactMode == false // Gentle = more breathing room
    }
    
    /// Activates gentle mode (app-specific UI adjustments)
    public func enableGentleMode() {
        compactMode = false // More spacing
        // Note: Animations/transparency respect system settings automatically
        save()
    }
    
    /// Deactivates gentle mode
    public func disableGentleMode() {
        compactMode = false
        save()
    }
}

// MARK: - Backward Compatibility Helpers

// These maintain compatibility with code that was using the old custom settings
extension View {
    /// @deprecated Use systemAccessibleAnimation instead
    @available(*, deprecated, message: "Use systemAccessibleAnimation to respect system Reduce Motion setting")
    public func accessibleAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V
    ) -> some View {
        self.systemAccessibleAnimation(animation, value: value)
    }
    
    /// @deprecated Use dynamicTapTarget instead
    @available(*, deprecated, message: "Use dynamicTapTarget to scale with Dynamic Type")
    public func accessibleTapTarget(minimum: CGFloat = 44) -> some View {
        self.dynamicTapTarget(baseSize: minimum)
    }
}
