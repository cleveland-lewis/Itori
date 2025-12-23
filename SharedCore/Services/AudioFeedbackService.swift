import Foundation
import AVFoundation

/// Manages audio feedback for timer events
@MainActor
final class AudioFeedbackService {
    static let shared = AudioFeedbackService()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private let settings = AppSettingsModel.shared
    
    private init() {
        setupAudio()
    }
    
    private func setupAudio() {
        // Configure audio session for ambient audio (doesn't interrupt other audio)
        #if os(macOS)
        // macOS doesn't need audio session configuration
        #else
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        #endif
    }
    
    /// Play timer start sound (pleasant upward tone)
    func playTimerStart() {
        guard settings.timerAlertsEnabled else { return }
        playSound(frequency: 800, duration: 0.15, volume: 0.3)
    }
    
    /// Play timer pause sound (slightly downtone)
    func playTimerPause() {
        guard settings.timerAlertsEnabled else { return }
        playSound(frequency: 600, duration: 0.15, volume: 0.3)
    }
    
    /// Play timer end sound (flat neutral tone)
    func playTimerEnd() {
        guard settings.timerAlertsEnabled else { return }
        playSound(frequency: 700, duration: 0.25, volume: 0.3)
    }
    
    /// Generate and play a simple sine wave tone
    private nonisolated func playSound(frequency: Double, duration: TimeInterval, volume: Float) {
        // Generate audio buffer with sine wave
        let sampleRate: Double = 44100
        let frameCount = Int(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            return
        }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
            return
        }
        
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: Int(format.channelCount))
        guard let channel = channels.first else { return }
        
        // Generate sine wave with fade in/out envelope
        for frame in 0..<frameCount {
            let time = Double(frame) / sampleRate
            let sine = sin(2.0 * .pi * frequency * time)
            
            // Apply envelope (fade in/out)
            let fadeLength = min(frameCount / 10, 1000) // 10% fade or max 1000 samples
            var envelope: Float = 1.0
            
            if frame < fadeLength {
                envelope = Float(frame) / Float(fadeLength)
            } else if frame > frameCount - fadeLength {
                envelope = Float(frameCount - frame) / Float(fadeLength)
            }
            
            channel[frame] = Float(sine) * volume * envelope
        }
        
        // Play the buffer
        let player = AVAudioPlayerNode()
        let engine = AVAudioEngine()
        
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        do {
            try engine.start()
            player.scheduleBuffer(buffer, at: nil, options: .interrupts) {
                // Cleanup after playing
                DispatchQueue.main.async {
                    engine.stop()
                }
            }
            player.play()
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    /// Alternative: Play system sounds (fallback if synthesis doesn't work)
    func playSystemSound(_ soundID: SystemSoundID) {
        guard settings.timerAlertsEnabled else { return }
        #if os(macOS)
        AudioServicesPlaySystemSound(soundID)
        #endif
    }
}

// MARK: - System Sound IDs (macOS)
extension AudioFeedbackService {
    /// Common macOS system sounds
    enum SystemSound {
        static let ping: SystemSoundID = 1103
        static let pop: SystemSoundID = 1104
        static let submarine: SystemSoundID = 1105
        static let tink: SystemSoundID = 1106
        static let funky: SystemSoundID = 1110
    }
}
