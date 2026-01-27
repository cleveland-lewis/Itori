import Combine
import Foundation
import SwiftUI

/// Feature flag system for progressive rollout and A/B testing
/// Flags default to OFF for all new features to ensure regression-free deployment
@MainActor
public final class FeatureFlags: ObservableObject {
    public static let shared = FeatureFlags()
    
    private let defaults = UserDefaults.standard
    private let prefix = "Itori.FeatureFlag."
    
    // MARK: - Timer Enhancement Flags (Phase A - Core Safe Wins)
    
    /// Dynamic countdown visuals (ring/grid modes)
    @Published public var dynamicCountdownVisuals: Bool {
        didSet { save(\.dynamicCountdownVisuals, dynamicCountdownVisuals) }
    }
    
    /// Quick Timer presets with user customization
    @Published public var quickTimerPresets: Bool {
        didSet { save(\.quickTimerPresets, quickTimerPresets) }
    }
    
    /// Timer Hub view (read-only history and analytics)
    @Published public var timerHub: Bool {
        didSet { save(\.timerHub, timerHub) }
    }
    
    // MARK: - Timer Enhancement Flags (Phase B - Non-Breaking Extensions)
    
    /// Custom timer themes and color schemes
    @Published public var timerThemes: Bool {
        didSet { save(\.timerThemes, timerThemes) }
    }
    
    /// Advanced timer statistics and insights
    @Published public var timerInsights: Bool {
        didSet { save(\.timerInsights, timerInsights) }
    }
    
    // MARK: - Timer Enhancement Flags (Phase C - Experimental)
    
    /// AI-based timer suggestions and recommendations
    @Published public var aiTimerSuggestions: Bool {
        didSet { save(\.aiTimerSuggestions, aiTimerSuggestions) }
    }
    
    /// Cross-device timer sync (beyond iCloud)
    @Published public var crossDeviceSync: Bool {
        didSet { save(\.crossDeviceSync, crossDeviceSync) }
    }
    
    /// Timer collaboration features
    @Published public var timerCollaboration: Bool {
        didSet { save(\.timerCollaboration, timerCollaboration) }
    }
    
    // MARK: - Platform-Specific Flags
    
    /// iOS Dynamic Island integration
    @Published public var dynamicIslandTimer: Bool {
        didSet { save(\.dynamicIslandTimer, dynamicIslandTimer) }
    }
    
    /// iOS Lock Screen widget enhancements
    @Published public var lockScreenWidgetEnhancements: Bool {
        didSet { save(\.lockScreenWidgetEnhancements, lockScreenWidgetEnhancements) }
    }
    
    /// macOS Menu Bar timer enhancements
    @Published public var menuBarTimerEnhancements: Bool {
        didSet { save(\.menuBarTimerEnhancements, menuBarTimerEnhancements) }
    }
    
    // MARK: - Development & Testing Flags
    
    /// Enable all timer features for testing (dev mode only)
    @Published public var enableAllTimerFeatures: Bool {
        didSet { save(\.enableAllTimerFeatures, enableAllTimerFeatures) }
    }
    
    /// High-precision timer tick for debugging
    @Published public var highPrecisionTimerTick: Bool {
        didSet { save(\.highPrecisionTimerTick, highPrecisionTimerTick) }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load all flags from UserDefaults with safe defaults (all OFF)
        self.dynamicCountdownVisuals = defaults.bool(forKey: "\(prefix)dynamicCountdownVisuals")
        self.quickTimerPresets = defaults.bool(forKey: "\(prefix)quickTimerPresets")
        self.timerHub = defaults.bool(forKey: "\(prefix)timerHub")
        self.timerThemes = defaults.bool(forKey: "\(prefix)timerThemes")
        self.timerInsights = defaults.bool(forKey: "\(prefix)timerInsights")
        self.aiTimerSuggestions = defaults.bool(forKey: "\(prefix)aiTimerSuggestions")
        self.crossDeviceSync = defaults.bool(forKey: "\(prefix)crossDeviceSync")
        self.timerCollaboration = defaults.bool(forKey: "\(prefix)timerCollaboration")
        self.dynamicIslandTimer = defaults.bool(forKey: "\(prefix)dynamicIslandTimer")
        self.lockScreenWidgetEnhancements = defaults.bool(forKey: "\(prefix)lockScreenWidgetEnhancements")
        self.menuBarTimerEnhancements = defaults.bool(forKey: "\(prefix)menuBarTimerEnhancements")
        self.enableAllTimerFeatures = defaults.bool(forKey: "\(prefix)enableAllTimerFeatures")
        self.highPrecisionTimerTick = defaults.bool(forKey: "\(prefix)highPrecisionTimerTick")
    }
    
    // MARK: - Persistence
    
    private func save<T>(_ keyPath: KeyPath<FeatureFlags, T>, _ value: T) where T == Bool {
        let key = "\(prefix)\(String(describing: keyPath))"
        defaults.set(value, forKey: key)
        print("[FeatureFlags] Updated \(key) = \(value)")
        objectWillChange.send()
    }
    
    // MARK: - Rollout Control
    
    /// Enable Phase A features (safe, additive UI)
    public func enablePhaseA() {
        dynamicCountdownVisuals = true
        quickTimerPresets = true
        timerHub = true
        print("[FeatureFlags] Enabled Phase A features")
    }
    
    /// Enable Phase B features (non-breaking extensions)
    public func enablePhaseB() {
        enablePhaseA()
        timerThemes = true
        timerInsights = true
        print("[FeatureFlags] Enabled Phase B features")
    }
    
    /// Enable Phase C features (experimental)
    public func enablePhaseC() {
        enablePhaseB()
        aiTimerSuggestions = true
        crossDeviceSync = true
        timerCollaboration = true
        print("[FeatureFlags] Enabled Phase C features")
    }
    
    /// Disable all timer enhancement features (emergency rollback)
    public func disableAllTimerEnhancements() {
        dynamicCountdownVisuals = false
        quickTimerPresets = false
        timerHub = false
        timerThemes = false
        timerInsights = false
        aiTimerSuggestions = false
        crossDeviceSync = false
        timerCollaboration = false
        dynamicIslandTimer = false
        lockScreenWidgetEnhancements = false
        menuBarTimerEnhancements = false
        print("[FeatureFlags WARNING] Disabled all timer enhancement features")
    }
    
    /// Reset all flags to defaults (all OFF)
    public func resetToDefaults() {
        disableAllTimerEnhancements()
        enableAllTimerFeatures = false
        highPrecisionTimerTick = false
        print("[FeatureFlags] Reset all feature flags to defaults")
    }
    
    // MARK: - Development Helpers
    
    #if DEBUG
    /// Enable all features for development/testing
    public func enableAllForDevelopment() {
        enablePhaseC()
        dynamicIslandTimer = true
        lockScreenWidgetEnhancements = true
        menuBarTimerEnhancements = true
        enableAllTimerFeatures = true
        print("[FeatureFlags DEBUG] Enabled all features for development")
    }
    #endif
}

// MARK: - Convenience Extensions

extension FeatureFlags {
    /// Check if any Phase A features are enabled
    public var hasPhaseAFeatures: Bool {
        dynamicCountdownVisuals || quickTimerPresets || timerHub
    }
    
    /// Check if any Phase B features are enabled
    public var hasPhaseBFeatures: Bool {
        timerThemes || timerInsights
    }
    
    /// Check if any Phase C features are enabled
    public var hasPhaseCFeatures: Bool {
        aiTimerSuggestions || crossDeviceSync || timerCollaboration
    }
    
    /// Check if any timer enhancement is enabled
    public var hasAnyTimerEnhancement: Bool {
        hasPhaseAFeatures || hasPhaseBFeatures || hasPhaseCFeatures
    }
}

// MARK: - Environment Key

private struct FeatureFlagsKey: EnvironmentKey {
    static let defaultValue = FeatureFlags.shared
}

extension EnvironmentValues {
    public var featureFlags: FeatureFlags {
        get { self[FeatureFlagsKey.self] }
        set { self[FeatureFlagsKey.self] = newValue }
    }
}
