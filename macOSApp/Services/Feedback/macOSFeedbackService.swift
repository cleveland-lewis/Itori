import AppKit
import AVFoundation

/// macOS implementation of FeedbackService (sound only, no haptics)
final class macOSFeedbackService: FeedbackService {
    init() {}
    
    var supportsHaptics: Bool { false }
    var supportsSound: Bool { true }
    
    func play(_ event: FeedbackEvent) async {
        let coordinator = await FeedbackCoordinator.shared
        
        // macOS doesn't support haptics, only play sound if enabled
        if await coordinator.soundEnabled {
            await MainActor.run {
                playSound(for: event)
            }
        }
    }
    
    private func playSound(for event: FeedbackEvent) {
        let sound: NSSound?
        
        switch event {
        case .taskCompleted, .success:
            sound = NSSound(named: .glass)
        case .timerStart:
            sound = NSSound(named: .pop)
        case .timerStop:
            sound = NSSound(named: .pop)
        case .warning:
            sound = NSSound(named: .ping)
        case .error:
            sound = NSSound(named: .basso)
        }
        
        sound?.play()
    }
}
