import UIKit
import AVFoundation

/// iOS/iPadOS implementation of FeedbackService with haptics + sound
final class iOSFeedbackService: FeedbackService {
    private let audioEngine = AVAudioEngine()
    private var audioPlayers: [FeedbackEvent: AVAudioPlayer] = [:]
    
    init() {
        setupAudio()
    }
    
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
        let generator: Any
        
        switch event {
        case .taskCompleted, .success:
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.success)
            generator = notificationGenerator
            
        case .error:
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.error)
            generator = notificationGenerator
            
        case .warning:
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.warning)
            generator = notificationGenerator
            
        case .timerStart:
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
            generator = impactGenerator
            
        case .timerStop:
            let impactGenerator = UIImpactFeedbackGenerator(style: .light)
            impactGenerator.impactOccurred()
            generator = impactGenerator
        }
        
        withExtendedLifetime(generator) { }
    }
    
    private func setupAudio() {
        // Configure audio session for brief sound effects
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    private func playSound(for event: FeedbackEvent) {
        // Use system sounds for now (can be replaced with custom sounds later)
        let soundID: SystemSoundID
        
        switch event {
        case .taskCompleted, .success:
            soundID = 1057 // Tink.caf
        case .timerStart:
            soundID = 1103 // BeginRecord.caf
        case .timerStop:
            soundID = 1114 // EndRecord.caf
        case .warning:
            soundID = 1053 // Tock.caf
        case .error:
            soundID = 1006 // Basso.caf
        }
        
        AudioServicesPlaySystemSound(soundID)
    }
}
