import SwiftUI

/// Runtime contract for interface preferences.
/// This is a derived, immutable value that represents the resolved UI state.
/// All views must consume this from environment - never read settings directly.
@MainActor
struct InterfacePreferences: Equatable {
    // MARK: - Accessibility Flags
    
    let reduceMotion: Bool
    let increaseContrast: Bool
    let reduceTransparency: Bool
    
    // MARK: - Derived Tokens
    
    let spacing: SpacingTokens
    let materials: MaterialTokens
    let animation: AnimationTokens
    let cornerRadius: CornerRadiusTokens
    let typography: TypographyTokens
    let haptics: HapticsTokens
    let tooltips: TooltipsTokens
    
    // MARK: - Layout Preferences
    
    let compactDensity: Bool
    let largeTapTargets: Bool
    let materialIntensity: Double
    
    // MARK: - Default
    
    static let `default` = InterfacePreferences(
        reduceMotion: false,
        increaseContrast: false,
        reduceTransparency: false,
        spacing: .standard,
        materials: .standard(intensity: 0.5),
        animation: .standard,
        cornerRadius: .standard,
        typography: .standard,
        haptics: .enabled,
        tooltips: .enabled,
        compactDensity: false,
        largeTapTargets: false,
        materialIntensity: 0.5
    )
    
    // MARK: - Spacing Tokens
    
    struct SpacingTokens: Equatable {
        let xxs: CGFloat
        let xs: CGFloat
        let sm: CGFloat
        let md: CGFloat
        let lg: CGFloat
        let xl: CGFloat
        let xxl: CGFloat
        let xxxl: CGFloat
        
        let cardPadding: CGFloat
        let listRowVerticalPadding: CGFloat
        let listRowHorizontalPadding: CGFloat
        let sectionSpacing: CGFloat
        let gridGap: CGFloat
        
        static let standard = SpacingTokens(
            xxs: 4,
            xs: 8,
            sm: 12,
            md: 16,
            lg: 24,
            xl: 32,
            xxl: 40,
            xxxl: 56,
            cardPadding: 16,
            listRowVerticalPadding: 8,
            listRowHorizontalPadding: 16,
            sectionSpacing: 24,
            gridGap: 24
        )
        
        static let compact = SpacingTokens(
            xxs: 2,
            xs: 4,
            sm: 8,
            md: 12,
            lg: 16,
            xl: 24,
            xxl: 32,
            xxxl: 40,
            cardPadding: 12,
            listRowVerticalPadding: 4,
            listRowHorizontalPadding: 12,
            sectionSpacing: 16,
            gridGap: 16
        )
        
        static let largeTapTarget = SpacingTokens(
            xxs: 6,
            xs: 12,
            sm: 16,
            md: 20,
            lg: 28,
            xl: 36,
            xxl: 44,
            xxxl: 60,
            cardPadding: 20,
            listRowVerticalPadding: 12,
            listRowHorizontalPadding: 20,
            sectionSpacing: 28,
            gridGap: 28
        )
    }
    
    // MARK: - Material Tokens
    
    struct MaterialTokens: Equatable {
        let cardMaterial: MaterialType
        let hudMaterial: MaterialType
        let popupMaterial: MaterialType
        let overlayMaterial: MaterialType
        
        let borderOpacity: Double
        let borderWidth: CGFloat
        let separatorOpacity: Double
        
        enum MaterialType: Equatable {
            case material(Material)
            case solid(Color)
            
            static func == (lhs: MaterialType, rhs: MaterialType) -> Bool {
                switch (lhs, rhs) {
                case (.material(let l), .material(let r)):
                    return String(describing: l) == String(describing: r)
                case (.solid(let l), .solid(let r)):
                    return l == r
                default:
                    return false
                }
            }
        }
        
        static func standard(intensity: Double) -> MaterialTokens {
            MaterialTokens(
                cardMaterial: .material(.regularMaterial),
                hudMaterial: .material(.ultraThinMaterial),
                popupMaterial: .material(.thickMaterial),
                overlayMaterial: .material(.thinMaterial),
                borderOpacity: 0.12,
                borderWidth: 1.0,
                separatorOpacity: 0.1
            )
        }
        
        static func reduceTransparency(colorScheme: ColorScheme) -> MaterialTokens {
            #if os(macOS)
            let cardColor = Color(nsColor: .textBackgroundColor)
            let hudColor = Color(nsColor: .controlBackgroundColor).opacity(0.95)
            #else
            let cardColor = Color(uiColor: .systemBackground)
            let hudColor = Color(uiColor: .secondarySystemBackground).opacity(0.95)
            #endif
            
            return MaterialTokens(
                cardMaterial: .solid(cardColor),
                hudMaterial: .solid(hudColor),
                popupMaterial: .solid(cardColor),
                overlayMaterial: .solid(hudColor),
                borderOpacity: 0.15,
                borderWidth: 1.0,
                separatorOpacity: 0.15
            )
        }
        
        static func increaseContrast(intensity: Double) -> MaterialTokens {
            MaterialTokens(
                cardMaterial: .material(.regularMaterial),
                hudMaterial: .material(.ultraThinMaterial),
                popupMaterial: .material(.thickMaterial),
                overlayMaterial: .material(.thinMaterial),
                borderOpacity: 0.3,
                borderWidth: 1.5,
                separatorOpacity: 0.25
            )
        }
    }
    
    // MARK: - Animation Tokens
    
    struct AnimationTokens: Equatable {
        let enabled: Bool
        let showAnimations: Bool
        
        let quick: Animation?
        let standard: Animation?
        let deliberate: Animation?
        let spring: Animation?
        
        static let standard = AnimationTokens(
            enabled: true,
            showAnimations: true,
            quick: .easeOut(duration: 0.15),
            standard: .easeInOut(duration: 0.25),
            deliberate: .easeInOut(duration: 0.35),
            spring: .spring(response: 0.3, dampingFraction: 0.7)
        )
        
        static let reduceMotion = AnimationTokens(
            enabled: false,
            showAnimations: false,
            quick: nil,
            standard: nil,
            deliberate: nil,
            spring: nil
        )
    }
    
    // MARK: - Corner Radius Tokens
    
    struct CornerRadiusTokens: Equatable {
        let small: CGFloat
        let medium: CGFloat
        let large: CGFloat
        let xlarge: CGFloat
        
        let card: CGFloat
        let button: CGFloat
        let field: CGFloat
        
        static let standard = CornerRadiusTokens(
            small: 8,
            medium: 12,
            large: 16,
            xlarge: 20,
            card: 16,
            button: 10,
            field: 8
        )
        
        static let compact = CornerRadiusTokens(
            small: 6,
            medium: 10,
            large: 14,
            xlarge: 18,
            card: 14,
            button: 8,
            field: 6
        )
    }
    
    // MARK: - Typography Tokens
    
    struct TypographyTokens: Equatable {
        let scaleMultiplier: CGFloat
        
        static let standard = TypographyTokens(scaleMultiplier: 1.0)
        static let largeTapTarget = TypographyTokens(scaleMultiplier: 1.15)
    }
    
    // MARK: - Haptics Tokens
    
    struct HapticsTokens: Equatable {
        let enabled: Bool
        
        static let enabled = HapticsTokens(enabled: true)
        static let disabled = HapticsTokens(enabled: false)
    }
    
    // MARK: - Tooltips Tokens
    
    struct TooltipsTokens: Equatable {
        let enabled: Bool
        
        static let enabled = TooltipsTokens(enabled: true)
        static let disabled = TooltipsTokens(enabled: false)
    }
}
