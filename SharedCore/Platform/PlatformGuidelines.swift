import SwiftUI

// MARK: - Platform-Specific Design Guidelines

/// # Platform Design Rules
/// This file documents the specific design rules and constraints for each platform

// MARK: - watchOS Guidelines
enum WatchOSGuidelines {
    /// Maximum navigation depth: 2 levels
    static let maxNavigationDepth = 2
    
    /// Preferred card corner radius
    static let cardCornerRadius: CGFloat = 8
    
    /// Minimum tap target
    static let minTapTarget: CGFloat = 44
    
    /// Content should be glanceable (3 seconds or less)
    static let maxGlanceDuration: TimeInterval = 3
    
    /// Use Digital Crown for scrolling and value input
    static let useDigitalCrown = true
    
    /// Design rules:
    /// - Show 1-2 key items per screen
    /// - Use large, clear typography
    /// - Avoid text input when possible
    /// - Use complications for at-a-glance info
    /// - Keep interactions to 2-3 taps maximum
    /// - Use haptic feedback liberally
    /// - Design for wrist-up interactions (5-10 seconds)
}

// MARK: - iOS Guidelines
enum IOSGuidelines {
    /// Maximum navigation depth: 4 levels
    static let maxNavigationDepth = 4
    
    /// Preferred card corner radius
    static let cardCornerRadius: CGFloat = 12
    
    /// Minimum tap target
    static let minTapTarget: CGFloat = 44
    
    /// Use tab bar for primary navigation
    static let primaryNavigation = NavigationPattern.tabBar
    
    /// Prefer full-screen modals
    static let modalStyle = ModalStyle.fullScreen
    
    /// Design rules:
    /// - Single focus per screen
    /// - 3-5 key items visible
    /// - Full-screen immersive experiences
    /// - Bottom tab bar (max 5 items)
    /// - Swipe gestures for navigation
    /// - Avoid hover-dependent UI
    /// - Portrait-first design
    /// - Support Dynamic Type
    /// - Use native alerts and action sheets
    
    enum NavigationPattern {
        case tabBar
        case stack
    }
    
    enum ModalStyle {
        case fullScreen
        case sheet
        case popover
    }
}

// MARK: - iPadOS Guidelines
enum IPadOSGuidelines {
    /// Maximum navigation depth: 6 levels
    static let maxNavigationDepth = 6
    
    /// Preferred card corner radius
    static let cardCornerRadius: CGFloat = 16
    
    /// Minimum tap target (with pointer support)
    static let minTapTarget: CGFloat = 40
    
    /// Use sidebar for primary navigation
    static let primaryNavigation = NavigationPattern.sidebar
    
    /// Prefer split views
    static let layoutStyle = LayoutStyle.splitView
    
    /// Design rules:
    /// - Flexible productivity focus
    /// - 5-8 key items visible
    /// - Multi-pane layouts (split views)
    /// - Sidebar + detail view pattern
    /// - Support keyboard shortcuts (but not required)
    /// - Support Apple Pencil
    /// - Support trackpad/mouse hover
    /// - Support drag and drop
    /// - Both portrait and landscape
    /// - Adaptive layouts for multitasking
    
    /// What iPadOS inherits from macOS:
    /// ✓ Keyboard shortcuts (subset)
    /// ✓ Hover effects (optional)
    /// ✓ Context menus
    /// ✓ Multi-window support
    /// ✓ Drag and drop
    /// ✓ Pointer precision
    
    /// What iPadOS does NOT inherit from macOS:
    /// ✗ Menu bar metaphors
    /// ✗ Mandatory hover-only UI
    /// ✗ Window chrome customization
    /// ✗ Multi-column file browsers
    /// ✗ Toolbar as primary control surface
    
    enum NavigationPattern {
        case sidebar
        case splitView
    }
    
    enum LayoutStyle {
        case splitView
        case multiPane
    }
}

// MARK: - macOS Guidelines
enum MacOSGuidelines {
    /// Maximum navigation depth: 8 levels
    static let maxNavigationDepth = 8
    
    /// Preferred card corner radius
    static let cardCornerRadius: CGFloat = 12
    
    /// Minimum click target (pointer precision)
    static let minClickTarget: CGFloat = 28
    
    /// Use sidebar + toolbar for primary navigation
    static let primaryNavigation = NavigationPattern.sidebarWithToolbar
    
    /// Prefer three-column layout
    static let layoutStyle = LayoutStyle.threeColumn
    
    /// Design rules:
    /// - Maximum power and control
    /// - 10+ items with rich detail
    /// - Multi-window, multi-pane layouts
    /// - Three-column navigation (sidebar + content + inspector)
    /// - Menu bar for all commands
    /// - Full keyboard control (every action)
    /// - Pointer-first interactions
    /// - Hover states required
    /// - Window management (resize, minimize, full-screen)
    /// - Advanced features visible by default
    /// - Toolbars with customization
    /// - Preference panes with extensive options
    
    /// macOS-exclusive features:
    /// - Menu bar integration
    /// - Window chrome customization
    /// - Keyboard as primary input
    /// - Right-click context everywhere
    /// - Command palette (Cmd+K)
    /// - Multiple monitor support
    /// - System-level keyboard shortcuts
    
    enum NavigationPattern {
        case sidebarWithToolbar
        case multiColumn
    }
    
    enum LayoutStyle {
        case threeColumn
        case multiWindow
    }
}

// MARK: - Cross-Platform Consistency Rules
enum CrossPlatformRules {
    /// Shared visual language
    struct VisualLanguage {
        /// Use same color palette across platforms
        static let useSharedColors = true
        
        /// Use same typography scale (with platform adjustments)
        static let useSharedTypography = true
        
        /// Use same icon system
        static let useSharedIcons = true
        
        /// Use same corner radius scale
        static let cornerRadiusScale: [PlatformTier: CGFloat] = [
            .watchOS: 8,
            .iOS: 12,
            .iPadOS: 16,
            .macOS: 12
        ]
    }
    
    /// Behavioral consistency
    struct Behavior {
        /// Same feature should work similarly across platforms
        static let consistentFeatureBehavior = true
        
        /// Data model should be identical
        static let sharedDataModel = true
        
        /// Sync state should be transparent
        static let visibleSyncState = true
        
        /// Errors should be handled consistently
        static let consistentErrorHandling = true
    }
    
    /// Platform differentiation
    struct Differentiation {
        /// Respect platform idioms
        static let respectPlatformIdioms = true
        
        /// Don't force feature parity
        static let allowFeatureDifferences = true
        
        /// Optimize for platform strengths
        static let platformOptimization = true
        
        /// Never make platforms "lesser clones"
        static let noLesserClones = true
    }
}

// MARK: - Anti-Pattern Detection
enum AntiPatterns {
    /// Things to avoid
    
    /// ❌ iPadOS as macOS clone
    static func detectIPadOSAsMacOSClone() -> Bool {
        // Check if iPadOS is trying to be macOS
        let hasMenuBar = CapabilityDomain.Visual.hasMenuBar && Platform.isTablet
        let hasWindowChrome = CapabilityDomain.Visual.supportsCustomWindowChrome && Platform.isTablet
        return hasMenuBar || hasWindowChrome
    }
    
    /// ❌ iOS inheriting iPadOS complexity
    static func detectIOSInheritingIPadOSComplexity() -> Bool {
        // Check if iOS has multi-pane layouts
        let hasMultiPane = CapabilityDomain.Layout.supportsMultiPane && Platform.isPhone
        let hasSidebar = CapabilityDomain.Visual.prefersSidebar && Platform.isPhone
        return hasMultiPane || hasSidebar
    }
    
    /// ❌ Desktop paradigms on touch devices
    static func detectDesktopParadigmsOnTouch() -> Bool {
        // Check if touch devices require hover
        let requiresHover = !CapabilityDomain.Interaction.supportsHover &&
                           Platform.current <= .iPadOS
        return requiresHover
    }
    
    /// ❌ Forced feature parity
    static func detectForcedFeatureParity() -> Bool {
        // All platforms should NOT have identical feature sets
        return false // This is good
    }
    
    /// ❌ watchOS with deep navigation
    static func detectWatchOSDeepNavigation() -> Bool {
        let depth = CapabilityDomain.Layout.maxNavigationDepth
        return Platform.isWatch && depth > WatchOSGuidelines.maxNavigationDepth
    }
}

// MARK: - Platform Validation
struct PlatformValidation {
    /// Validate that platform rules are being followed
    static func validate() -> [ValidationError] {
        var errors: [ValidationError] = []
        
        if AntiPatterns.detectIPadOSAsMacOSClone() {
            errors.append(.iPadOSAsMacOSClone)
        }
        
        if AntiPatterns.detectIOSInheritingIPadOSComplexity() {
            errors.append(.iOSInheritingIPadOSComplexity)
        }
        
        if AntiPatterns.detectDesktopParadigmsOnTouch() {
            errors.append(.desktopParadigmsOnTouch)
        }
        
        if AntiPatterns.detectWatchOSDeepNavigation() {
            errors.append(.watchOSDeepNavigation)
        }
        
        return errors
    }
    
    enum ValidationError: Error, CustomStringConvertible {
        case iPadOSAsMacOSClone
        case iOSInheritingIPadOSComplexity
        case desktopParadigmsOnTouch
        case watchOSDeepNavigation
        
        var description: String {
            switch self {
            case .iPadOSAsMacOSClone:
                return "❌ iPadOS is acting as a macOS clone (menu bar or window chrome)"
            case .iOSInheritingIPadOSComplexity:
                return "❌ iOS is inheriting iPadOS complexity (multi-pane or sidebar)"
            case .desktopParadigmsOnTouch:
                return "❌ Desktop paradigms are being used on touch devices (hover-required)"
            case .watchOSDeepNavigation:
                return "❌ watchOS has navigation depth > 2"
            }
        }
    }
}

// MARK: - Platform Testing Helper
#if DEBUG
struct PlatformDebugView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Platform Debug Info")
                    .font(.largeTitle)
                    .bold()
                
                platformInfo
                capabilityMatrix
                validationResults
            }
            .padding()
        }
    }
    
    private var platformInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Platform")
                .font(.headline)
            Text("Tier: \(String(describing: Platform.current))")
            Text("Is Watch: \(Platform.isWatch.description)")
            Text("Is Phone: \(Platform.isPhone.description)")
            Text("Is Tablet: \(Platform.isTablet.description)")
            Text("Is Desktop: \(Platform.isDesktop.description)")
        }
    }
    
    private var capabilityMatrix: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Capabilities")
                .font(.headline)
            
            Group {
                capability("Multi-pane", CapabilityDomain.Layout.supportsMultiPane)
                capability("Persistent sidebar", CapabilityDomain.Layout.supportsPersistentSidebar)
                capability("Floating panels", CapabilityDomain.Layout.supportsFloatingPanels)
                capability("Hover", CapabilityDomain.Interaction.supportsHover)
                capability("Keyboard shortcuts", CapabilityDomain.Interaction.supportsKeyboardShortcuts)
                capability("Rich context menus", CapabilityDomain.Interaction.supportsRichContextMenus)
                capability("Multiple windows", CapabilityDomain.Interaction.supportsMultipleWindows)
                capability("Menu bar", CapabilityDomain.Visual.hasMenuBar)
            }
        }
    }
    
    private var validationResults: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Validation")
                .font(.headline)
            
            let errors = PlatformValidation.validate()
            if errors.isEmpty {
                Text("✓ All platform rules validated")
                    .foregroundColor(.green)
            } else {
                ForEach(errors, id: \.localizedDescription) { error in
                    Text(error.description)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private func capability(_ name: String, _ enabled: Bool) -> some View {
        HStack {
            Text(name)
            Spacer()
            Text(enabled ? "✓" : "✗")
                .foregroundColor(enabled ? .green : .secondary)
        }
    }
}
#endif
