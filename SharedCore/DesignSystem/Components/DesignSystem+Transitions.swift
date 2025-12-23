import SwiftUI

/// Comprehensive transition system for Roots
/// Provides standardized, tokenized transitions for all UI surfaces
extension DesignSystem {
    public struct Transitions {
        
        // MARK: - Popup/Modal Transitions
        
        /// Standard popup presentation (fade + subtle scale)
        public static let popupPresentation: AnyTransition = .asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .opacity
        )
        
        /// Inline overlay (fade + slight move up)
        public static let inlineOverlay: AnyTransition = .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        )
        
        /// Sheet/modal from bottom
        public static let sheet: AnyTransition = .move(edge: .bottom)
        
        /// Alert/dialog fade
        public static let alert: AnyTransition = .scale(scale: 0.95).combined(with: .opacity)
        
        // MARK: - Text Input Transitions
        
        /// Focus ring appearance
        public static let focusRing: AnyTransition = .opacity
        
        /// Validation message appearance
        public static let validationMessage: AnyTransition = .move(edge: .top).combined(with: .opacity)
        
        /// Placeholder fade
        public static let placeholder: AnyTransition = .opacity
        
        // MARK: - Loading State Transitions
        
        /// Page-level loading overlay
        public static let loadingOverlay: AnyTransition = .opacity
        
        /// Inline loading indicator
        public static let loadingInline: AnyTransition = .opacity
        
        /// Skeleton placeholder
        public static let skeleton: AnyTransition = .opacity
        
        /// Content replacement (old out, new in)
        public static let contentReplacement: AnyTransition = .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        )
        
        // MARK: - List/Grid Transitions
        
        /// List item insertion
        public static let listItem: AnyTransition = .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        )
        
        /// Card appearance
        public static let card: AnyTransition = .scale(scale: 0.98).combined(with: .opacity)
        
        // MARK: - Navigation Transitions
        
        /// Page transition (cross-fade)
        public static let page: AnyTransition = .opacity
        
        /// Sidebar toggle
        public static let sidebar: AnyTransition = .move(edge: .leading).combined(with: .opacity)
        
        /// Tab switch
        public static let tab: AnyTransition = .opacity
        
        // MARK: - Reduce Motion Variants
        
        /// Get transition respecting Reduce Motion
        public static func transition(_ transition: AnyTransition, reduceMotion: Bool) -> AnyTransition {
            reduceMotion ? .opacity : transition
        }
    }
    
    // MARK: - Animation Durations
    
    public struct AnimationDurations {
        /// Popup/modal presentation
        public static let popup: TimeInterval = Motion.standard
        
        /// Text input focus
        public static let textFocus: TimeInterval = Motion.fast
        
        /// Validation message
        public static let validation: TimeInterval = Motion.fast
        
        /// Loading appearance
        public static let loading: TimeInterval = Motion.standard
        
        /// List item insertion
        public static let listItem: TimeInterval = Motion.fast
        
        /// Content replacement
        public static let contentSwap: TimeInterval = Motion.moderate
    }
    
    // MARK: - Animation Curves
    
    public struct AnimationCurves {
        /// Default easing for most UI
        public static let defaultCurve: Animation = .easeInOut(duration: Motion.standard)
        
        /// Emphasized curve for important transitions
        public static let emphasizedCurve: Animation = .spring(response: 0.4, dampingFraction: 0.85)
        
        /// Popup/modal curve
        public static let popupCurve: Animation = .spring(response: 0.35, dampingFraction: 0.8)
        
        /// Text input focus curve
        public static let focusCurve: Animation = .easeOut(duration: Motion.fast)
        
        /// Loading state curve
        public static let loadingCurve: Animation = .easeInOut(duration: Motion.standard)
        
        /// List insertion curve
        public static let listCurve: Animation = .spring(response: 0.3, dampingFraction: 0.75)
    }
}

// MARK: - View Modifiers for Standard Transitions

extension View {
    
    // MARK: - Popup/Modal Modifiers
    
    /// Apply standard popup presentation transition
    public func popupTransition() -> some View {
        self.transition(DesignSystem.Transitions.popupPresentation)
    }
    
    /// Apply inline overlay transition
    public func inlineOverlayTransition() -> some View {
        self.transition(DesignSystem.Transitions.inlineOverlay)
    }
    
    // MARK: - Text Input Modifiers
    
    /// Apply focus ring animation
    public func focusAnimation<V: Equatable>(value: V) -> some View {
        self
            .transition(DesignSystem.Transitions.focusRing)
            .animation(DesignSystem.AnimationCurves.focusCurve, value: value)
    }
    
    /// Apply validation message transition
    public func validationTransition() -> some View {
        self
            .transition(DesignSystem.Transitions.validationMessage)
            .animation(DesignSystem.AnimationCurves.defaultCurve, value: true)
    }
    
    // MARK: - Loading State Modifiers
    
    /// Apply loading overlay transition
    public func loadingTransition() -> some View {
        self
            .transition(DesignSystem.Transitions.loadingOverlay)
            .animation(DesignSystem.AnimationCurves.loadingCurve, value: true)
    }
    
    /// Apply content replacement transition
    public func contentReplacementTransition<V: Equatable>(value: V) -> some View {
        self
            .transition(DesignSystem.Transitions.contentReplacement)
            .animation(DesignSystem.AnimationCurves.defaultCurve, value: value)
    }
    
    // MARK: - List/Card Modifiers
    
    /// Apply list item insertion transition
    public func listItemTransition() -> some View {
        self
            .transition(DesignSystem.Transitions.listItem)
            .animation(DesignSystem.AnimationCurves.listCurve, value: true)
    }
    
    /// Apply card appearance transition
    public func cardTransition<V: Equatable>(value: V) -> some View {
        self
            .transition(DesignSystem.Transitions.card)
            .animation(DesignSystem.Motion.cardTransition, value: value)
    }
}

// MARK: - Reduce Motion Support

extension View {
    /// Apply transition with automatic Reduce Motion support
    public func adaptiveTransition(
        _ transition: AnyTransition,
        animation: Animation? = DesignSystem.AnimationCurves.defaultCurve
    ) -> some View {
        self.modifier(AdaptiveTransitionModifier(transition: transition, animation: animation))
    }
}

private struct AdaptiveTransitionModifier: ViewModifier {
    let transition: AnyTransition
    let animation: Animation?
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .transition(reduceMotion ? .opacity : transition)
            .animation(reduceMotion ? .easeInOut(duration: 0.1) : animation, value: UUID())
    }
}
