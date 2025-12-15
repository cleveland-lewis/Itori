import SwiftUI

extension DesignSystem {
    struct Motion {
        // MARK: - Durations (Standardized)
        static let instant: TimeInterval = 0.1
        static let fast: TimeInterval = 0.2
        static let standard: TimeInterval = 0.3
        static let moderate: TimeInterval = 0.4
        static let slow: TimeInterval = 0.5
        static let deliberate: TimeInterval = 0.6
        
        // MARK: - Easing Curves
        static let snappyEase: Animation = .easeInOut(duration: fast)
        static let standardEase: Animation = .easeInOut(duration: standard)
        static let smoothEase: Animation = .easeInOut(duration: moderate)
        static let gentleEase: Animation = .easeOut(duration: slow)
        
        // MARK: - Spring Animations (Standardized)
        /// Immediate feedback spring (button presses, toggles)
        static let interactiveSpring: Animation = .spring(response: 0.3, dampingFraction: 0.7)
        
        /// Standard UI transitions (modals, overlays)
        static let standardSpring: Animation = .spring(response: 0.3, dampingFraction: 0.85)
        
        /// Layout changes (resizing, reflow)
        static let layoutSpring: Animation = .spring(response: 0.5, dampingFraction: 0.8)
        
        /// Smooth, flowing (page transitions)
        static let fluidSpring: Animation = .spring(response: 0.4, dampingFraction: 0.9)
        
        /// Playful bounce (success states, fun interactions)
        static let wobblySpring: Animation = .spring(response: 0.4, dampingFraction: 0.5)
        
        // MARK: - Transitions
        static let fadeTransition: AnyTransition = .opacity
        static let slideUpTransition: AnyTransition = .move(edge: .bottom).combined(with: .opacity)
        static let slideDownTransition: AnyTransition = .move(edge: .top).combined(with: .opacity)
        static let slideLeadingTransition: AnyTransition = .move(edge: .leading).combined(with: .opacity)
        static let slideTrailingTransition: AnyTransition = .move(edge: .trailing).combined(with: .opacity)
        static let scaleTransition: AnyTransition = .scale(scale: 0.95).combined(with: .opacity)
        
        // MARK: - Reduce Motion Support
        @available(iOS 14.0, macOS 11.0, *)
        static func animation(_ animation: Animation, reduceMotion: Bool = false) -> Animation? {
            if reduceMotion {
                return .easeInOut(duration: instant)
            }
            return animation
        }
        
        @available(iOS 14.0, macOS 11.0, *)
        static func transition(_ transition: AnyTransition, reduceMotion: Bool = false) -> AnyTransition {
            if reduceMotion {
                return .opacity
            }
            return transition
        }
        
        // MARK: - Common Animation Patterns
        /// Standard page/tab transition
        static let pageTransition: Animation = standardSpring
        
        /// Modal/sheet presentation
        static let modalTransition: Animation = fluidSpring
        
        /// Overlay appearance (tooltips, popovers)
        static let overlayTransition: Animation = snappyEase
        
        /// Card expansion/collapse
        static let cardTransition: Animation = smoothEase
        
        /// Sidebar toggle
        static let sidebarTransition: Animation = standardSpring
        
        /// List item appearance (staggered entry)
        static func staggeredDelay(index: Int, base: TimeInterval = 0.05) -> TimeInterval {
            return Double(index) * base
        }
    }
}

// MARK: - View Modifiers for Consistent Animations

extension View {
    /// Apply standard interactive animation (buttons, toggles)
    func interactiveAnimation<V: Equatable>(value: V) -> some View {
        self.animation(DesignSystem.Motion.interactiveSpring, value: value)
    }
    
    /// Apply standard transition animation
    func standardTransition<V: Equatable>(value: V) -> some View {
        self.animation(DesignSystem.Motion.standardSpring, value: value)
    }
    
    /// Apply smooth transition animation
    func smoothTransition<V: Equatable>(value: V) -> some View {
        self.animation(DesignSystem.Motion.fluidSpring, value: value)
    }
    
    /// Apply staggered entry animation
    func staggeredEntry(isLoaded: Bool, index: Int) -> some View {
        self
            .opacity(isLoaded ? 1 : 0)
            .offset(y: isLoaded ? 0 : 20)
            .animation(
                DesignSystem.Motion.gentleEase.delay(DesignSystem.Motion.staggeredDelay(index: index)),
                value: isLoaded
            )
    }
}

// MARK: - Reduce Motion Environment Key

struct ReduceMotionKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var reduceMotion: Bool {
        get { self[ReduceMotionKey.self] }
        set { self[ReduceMotionKey.self] = newValue }
    }
}
