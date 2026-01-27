import SwiftUI
import CoreHaptics

/// Haptic feedback manager for timer interactions
/// Provides tactile feedback for key timer events
@MainActor
class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()
    
    private var engine: CHHapticEngine?
    private var supportsHaptics = false
    
    private init() {
        #if os(iOS)
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        prepareHaptics()
        #endif
    }
    
    private func prepareHaptics() {
        #if os(iOS)
        guard supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            LOG_UI(.error, "Haptics", "Failed to start haptic engine: \(error)")
        }
        #endif
    }
    
    // MARK: - Timer Event Haptics
    
    /// Haptic for timer start
    func timerStarted() {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        LOG_UI(.debug, "Haptics", "Timer started feedback")
        #endif
    }
    
    /// Haptic for timer paused
    func timerPaused() {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        LOG_UI(.debug, "Haptics", "Timer paused feedback")
        #endif
    }
    
    /// Haptic for timer completed
    func timerCompleted() {
        #if os(iOS)
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        
        // Add a subtle second pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
        LOG_UI(.debug, "Haptics", "Timer completed feedback")
        #endif
    }
    
    /// Haptic for preset button tap
    func presetTapped() {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif
    }
    
    /// Haptic for button press
    func buttonPressed() {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .rigid)
        impact.impactOccurred()
        #endif
    }
    
    /// Haptic for time warning (last 10 seconds)
    func timeWarning() {
        #if os(iOS)
        guard supportsHaptics, let engine = engine else {
            // Fallback to simple haptic
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            return
        }
        
        do {
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
            
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [sharpness, intensity],
                relativeTime: 0
            )
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            
            LOG_UI(.debug, "Haptics", "Time warning feedback")
        } catch {
            LOG_UI(.error, "Haptics", "Warning haptic failed: \(error)")
        }
        #endif
    }
    
    /// Haptic for selection change
    func selectionChanged() {
        #if os(iOS)
        let selection = UISelectionFeedbackGenerator()
        selection.selectionChanged()
        #endif
    }
    
    // MARK: - Advanced Patterns
    
    /// Celebration pattern for timer completion
    func celebrationPattern() {
        #if os(iOS)
        guard supportsHaptics, let engine = engine else {
            // Fallback
            timerCompleted()
            return
        }
        
        do {
            var events: [CHHapticEvent] = []
            
            // Create a burst pattern
            for i in 0..<3 {
                let intensity = CHHapticEventParameter(
                    parameterID: .hapticIntensity,
                    value: Float(0.8 - Double(i) * 0.2)
                )
                let sharpness = CHHapticEventParameter(
                    parameterID: .hapticSharpness,
                    value: 0.5
                )
                
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: TimeInterval(i) * 0.15
                )
                events.append(event)
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            
            LOG_UI(.debug, "Haptics", "Celebration pattern played")
        } catch {
            LOG_UI(.error, "Haptics", "Celebration haptic failed: \(error)")
        }
        #endif
    }
}

// MARK: - SwiftUI View Extensions

extension View {
    /// Add haptic feedback to button press
    func hapticFeedback(style: HapticStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    #if os(iOS)
                    switch style {
                    case .light:
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    case .medium:
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                    case .heavy:
                        let impact = UIImpactFeedbackGenerator(style: .heavy)
                        impact.impactOccurred()
                    case .soft:
                        let impact = UIImpactFeedbackGenerator(style: .soft)
                        impact.impactOccurred()
                    case .rigid:
                        let impact = UIImpactFeedbackGenerator(style: .rigid)
                        impact.impactOccurred()
                    }
                    #endif
                }
        )
    }
}

enum HapticStyle {
    case light, medium, heavy, soft, rigid
}
