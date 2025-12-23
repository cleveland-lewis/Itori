import WatchKit
import AVFoundation

/// watchOS implementation of FeedbackService with haptics + sound
final class watchOSFeedbackService: FeedbackService {
    init() {}
    
    var supportsHaptics: Bool { true }
    var supportsSound: Bool { true }
    
    func play(_ event: FeedbackEvent) async {
        let coordinator = await FeedbackCoordinator.shared
        
        // Play haptics if enabled
        if await coordinator.hapticsEnabled {
            await MainActor.run {
                playHaptic(for: event)
            }
        }
        
        // Play sound if enabled
        if await coordinator.soundEnabled {
            playSound(for: event)
        }
    }
    
    private func playHaptic(for event: FeedbackEvent) {
        let hapticType: WKHapticType
        
        switch event {
        case .taskCompleted, .success:
            hapticType = .success
        case .timerStart:
            hapticType = .start
        case .timerStop:
            hapticType = .stop
        case .warning:
            hapticType = .directionUp
        case .error:
            hapticType = .failure
        }
        
        WKInterfaceDevice.current().play(hapticType)
    }
    
    private func playSound(for event: FeedbackEvent) {
        // Use system sounds
        let soundID: SystemSoundID
        
        switch event {
        case .taskCompleted, .success:
            soundID = 1057 // Tink
        case .timerStart:
            soundID = 1103 // BeginRecord
        case .timerStop:
            soundID = 1114 // EndRecord
        case .warning:
            soundID = 1053 // Tock
        case .error:
            soundID = 1006 // Basso
        }
        
        AudioServicesPlaySystemSound(soundID)
    }
}
