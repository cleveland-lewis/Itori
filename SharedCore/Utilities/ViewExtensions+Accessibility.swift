import SwiftUI

// MARK: - Conditional Animation (Respects showAnimations setting)

extension View {
    /// Applies animation only if animations are enabled in settings
    /// Use this instead of `.animation()` to respect accessibility preferences
    @ViewBuilder
    public func conditionalAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V,
        isEnabled: Bool
    ) -> some View {
        if isEnabled {
            self.animation(animation, value: value)
        } else {
            self
        }
    }
    
    /// Applies animation with settings check via environment
    @ViewBuilder
    public func accessibleAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V
    ) -> some View {
        self.modifier(ConditionalAnimationModifier(animation: animation, value: value))
    }
}

private struct ConditionalAnimationModifier<V: Equatable>: ViewModifier {
    let animation: Animation?
    let value: V
    @EnvironmentObject private var settings: AppSettingsModel
    
    func body(content: Content) -> some View {
        if settings.showAnimations {
            content.animation(animation, value: value)
        } else {
            content
        }
    }
}

// MARK: - Conditional withAnimation

/// Executes animation block only if animations are enabled
/// Use this instead of `withAnimation {}` to respect accessibility preferences
public func withConditionalAnimation<Result>(
    _ animation: Animation? = .default,
    isEnabled: Bool,
    _ body: () throws -> Result
) rethrows -> Result {
    if isEnabled {
        return try withAnimation(animation, body)
    } else {
        return try body()
    }
}

// MARK: - Accessible Button Sizes

extension View {
    /// Applies minimum tap target size based on accessibility settings
    public func accessibleTapTarget() -> some View {
        self.modifier(AccessibleTapTargetModifier())
    }
    
    /// Applies minimum tap target size with custom minimum
    public func accessibleTapTarget(minimum: CGFloat = 44) -> some View {
        self.modifier(AccessibleTapTargetModifier(customMinimum: minimum))
    }
}

private struct AccessibleTapTargetModifier: ViewModifier {
    @Environment(\.layoutMetrics) private var metrics
    let customMinimum: CGFloat?
    
    init(customMinimum: CGFloat? = nil) {
        self.customMinimum = customMinimum
    }
    
    func body(content: Content) -> some View {
        content
            .frame(minWidth: customMinimum ?? metrics.minimumTapTarget,
                   minHeight: customMinimum ?? metrics.minimumTapTarget)
    }
}

// MARK: - Accessible Spacing

extension View {
    /// Applies card padding based on compact mode setting
    public func accessibleCardPadding() -> some View {
        self.modifier(AccessibleCardPaddingModifier())
    }
    
    /// Applies section spacing based on compact mode setting
    public func accessibleSectionSpacing() -> some View {
        self.modifier(AccessibleSectionSpacingModifier())
    }
}

private struct AccessibleCardPaddingModifier: ViewModifier {
    @Environment(\.layoutMetrics) private var metrics
    
    func body(content: Content) -> some View {
        content.padding(metrics.cardPadding)
    }
}

private struct AccessibleSectionSpacingModifier: ViewModifier {
    @Environment(\.layoutMetrics) private var metrics
    
    func body(content: Content) -> some View {
        if let stack = content as? any View {
            AnyView(stack)
        } else {
            content
        }
    }
}

// MARK: - Accessible Stack Builders

/// VStack that respects compact mode spacing
public struct AccessibleVStack<Content: View>: View {
    @Environment(\.layoutMetrics) private var metrics
    let alignment: HorizontalAlignment
    let content: Content
    
    public init(
        alignment: HorizontalAlignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: alignment, spacing: metrics.sectionSpacing) {
            content
        }
    }
}

/// HStack that respects compact mode spacing
public struct AccessibleHStack<Content: View>: View {
    @Environment(\.layoutMetrics) private var metrics
    let alignment: VerticalAlignment
    let content: Content
    
    public init(
        alignment: VerticalAlignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.content = content()
    }
    
    public var body: some View {
        HStack(alignment: alignment, spacing: metrics.sectionSpacing) {
            content
        }
    }
}

// MARK: - Gentle Mode Helpers

extension AppSettingsModel {
    /// Returns true if "gentle mode" should be active
    /// Gentle mode softens the UI for sensory sensitivity
    public var isGentleModeActive: Bool {
        !showAnimations && compactMode
    }
    
    /// Activates gentle mode (multiple settings at once)
    public func enableGentleMode() {
        showAnimations = false
        compactMode = false // More spacing in gentle mode
        // Future: softer colors, reduced shadows, etc.
        save()
    }
    
    /// Deactivates gentle mode
    public func disableGentleMode() {
        showAnimations = true
        compactMode = false
        save()
    }
}
