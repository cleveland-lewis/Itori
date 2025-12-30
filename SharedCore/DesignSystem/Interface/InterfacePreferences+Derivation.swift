import SwiftUI

extension InterfacePreferences {
    /// Derive preferences from settings store
    static func from(_ settings: AppSettingsModel, colorScheme: ColorScheme) -> InterfacePreferences {
        // Read from AppPreferences if available, fallback to AppSettingsModel storage
        let reduceMotion = settings.reduceMotionStorage
        let increaseContrast = settings.increaseContrastStorage
        let reduceTransparency = settings.reduceTransparencyStorage
        let compactDensity = settings.compactModeStorage
        let largeTapTargets = settings.largeTapTargetsStorage
        let materialIntensity = settings.glassIntensityStorage
        let showAnimations = settings.showAnimationsStorage
        let enableHaptics = settings.enableHapticsStorage
        let showTooltips = settings.showTooltipsStorage
        
        // Derive spacing tokens
        let spacing: SpacingTokens
        if largeTapTargets {
            spacing = .largeTapTarget
        } else if compactDensity {
            spacing = .compact
        } else {
            spacing = .standard
        }
        
        // Derive material tokens (reduce transparency takes precedence)
        let materials: MaterialTokens
        if reduceTransparency {
            materials = .reduceTransparency(colorScheme: colorScheme)
        } else if increaseContrast {
            materials = .increaseContrast(intensity: materialIntensity)
        } else {
            materials = .standard(intensity: materialIntensity)
        }
        
        // Derive animation tokens (reduce motion disables all animations)
        let animation: AnimationTokens
        if reduceMotion {
            animation = .reduceMotion
        } else {
            animation = AnimationTokens(
                enabled: showAnimations,
                showAnimations: showAnimations,
                quick: showAnimations ? .easeOut(duration: 0.15) : nil,
                standard: showAnimations ? .easeInOut(duration: 0.25) : nil,
                deliberate: showAnimations ? .easeInOut(duration: 0.35) : nil,
                spring: showAnimations ? .spring(response: 0.3, dampingFraction: 0.7) : nil
            )
        }
        
        // Derive corner radius tokens
        let cornerRadius: CornerRadiusTokens = compactDensity ? .compact : .standard
        
        // Derive typography tokens
        let typography: TypographyTokens = largeTapTargets ? .largeTapTarget : .standard
        
        // Derive haptics tokens (iOS only)
        #if os(iOS)
        let haptics: HapticsTokens = enableHaptics ? .enabled : .disabled
        #else
        let haptics: HapticsTokens = .disabled
        #endif
        
        // Derive tooltips tokens (macOS only)
        #if os(macOS)
        let tooltips: TooltipsTokens = showTooltips ? .enabled : .disabled
        #else
        let tooltips: TooltipsTokens = .disabled
        #endif
        
        return InterfacePreferences(
            reduceMotion: reduceMotion,
            increaseContrast: increaseContrast,
            reduceTransparency: reduceTransparency,
            spacing: spacing,
            materials: materials,
            animation: animation,
            cornerRadius: cornerRadius,
            typography: typography,
            haptics: haptics,
            tooltips: tooltips,
            compactDensity: compactDensity,
            largeTapTargets: largeTapTargets,
            materialIntensity: materialIntensity
        )
    }
    
    /// Derive preferences from AppPreferences
    static func from(_ preferences: AppPreferences, settings: AppSettingsModel, colorScheme: ColorScheme) -> InterfacePreferences {
        // Use AppPreferences as primary source, fallback to settings
        let reduceMotion = preferences.reduceMotion
        let increaseContrast = preferences.highContrast
        let reduceTransparency = preferences.reduceTransparency
        let compactDensity = settings.compactModeStorage
        let largeTapTargets = settings.largeTapTargetsStorage
        let materialIntensity = preferences.glassIntensity
        let showAnimations = settings.showAnimationsStorage
        let enableHaptics = preferences.enableHaptics
        let showTooltips = settings.showTooltipsStorage
        
        // Derive spacing tokens
        let spacing: SpacingTokens
        if largeTapTargets {
            spacing = .largeTapTarget
        } else if compactDensity {
            spacing = .compact
        } else {
            spacing = .standard
        }
        
        // Derive material tokens (reduce transparency takes precedence)
        let materials: MaterialTokens
        if reduceTransparency {
            materials = .reduceTransparency(colorScheme: colorScheme)
        } else if increaseContrast {
            materials = .increaseContrast(intensity: materialIntensity)
        } else {
            materials = .standard(intensity: materialIntensity)
        }
        
        // Derive animation tokens (reduce motion disables all animations)
        let animation: AnimationTokens
        if reduceMotion {
            animation = .reduceMotion
        } else {
            animation = AnimationTokens(
                enabled: showAnimations,
                showAnimations: showAnimations,
                quick: showAnimations ? .easeOut(duration: 0.15) : nil,
                standard: showAnimations ? .easeInOut(duration: 0.25) : nil,
                deliberate: showAnimations ? .easeInOut(duration: 0.35) : nil,
                spring: showAnimations ? .spring(response: 0.3, dampingFraction: 0.7) : nil
            )
        }
        
        // Derive corner radius tokens
        let cornerRadius: CornerRadiusTokens = compactDensity ? .compact : .standard
        
        // Derive typography tokens
        let typography: TypographyTokens = largeTapTargets ? .largeTapTarget : .standard
        
        // Derive haptics tokens (iOS only)
        #if os(iOS)
        let haptics: HapticsTokens = enableHaptics ? .enabled : .disabled
        #else
        let haptics: HapticsTokens = .disabled
        #endif
        
        // Derive tooltips tokens (macOS only)
        #if os(macOS)
        let tooltips: TooltipsTokens = showTooltips ? .enabled : .disabled
        #else
        let tooltips: TooltipsTokens = .disabled
        #endif
        
        return InterfacePreferences(
            reduceMotion: reduceMotion,
            increaseContrast: increaseContrast,
            reduceTransparency: reduceTransparency,
            spacing: spacing,
            materials: materials,
            animation: animation,
            cornerRadius: cornerRadius,
            typography: typography,
            haptics: haptics,
            tooltips: tooltips,
            compactDensity: compactDensity,
            largeTapTargets: largeTapTargets,
            materialIntensity: materialIntensity
        )
    }
}
