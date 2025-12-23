import Foundation

/// Protocol for platform-specific feedback implementations
public protocol FeedbackService: Sendable {
    /// Play feedback for the given event
    /// - Parameter event: The feedback event to trigger
    func play(_ event: FeedbackEvent) async
    
    /// Check if haptics are supported on this platform
    var supportsHaptics: Bool { get }
    
    /// Check if sound is supported on this platform
    var supportsSound: Bool { get }
}

/// Global feedback coordinator
@MainActor
public final class FeedbackCoordinator: ObservableObject {
    public static let shared = FeedbackCoordinator()
    
    @Published public var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: "FeedbackSoundEnabled")
        }
    }
    
    @Published public var hapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticsEnabled, forKey: "FeedbackHapticsEnabled")
        }
    }
    
    private var service: FeedbackService?
    
    private init() {
        self.soundEnabled = UserDefaults.standard.object(forKey: "FeedbackSoundEnabled") as? Bool ?? true
        self.hapticsEnabled = UserDefaults.standard.object(forKey: "FeedbackHapticsEnabled") as? Bool ?? true
    }
    
    /// Register the platform-specific service implementation
    public func register(service: FeedbackService) {
        self.service = service
    }
    
    /// Play feedback for the given event, respecting user settings
    public func play(_ event: FeedbackEvent) {
        guard soundEnabled || hapticsEnabled else { return }
        
        Task {
            await service?.play(event)
        }
    }
    
    /// Check if haptics are available on current platform
    public var supportsHaptics: Bool {
        service?.supportsHaptics ?? false
    }
    
    /// Check if sound is available on current platform
    public var supportsSound: Bool {
        service?.supportsSound ?? false
    }
}
