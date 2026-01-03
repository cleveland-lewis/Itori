import Foundation
import SwiftUI

// MARK: - Platform Hierarchy
/// Defines the capability hierarchy: watchOS → iOS → iPadOS → macOS
/// Lower platforms inherit from their level only
/// Higher platforms can selectively provide features to lower levels

enum PlatformTier: Int, Comparable {
    case watchOS = 0
    case iOS = 1
    case iPadOS = 2
    case macOS = 3
    
    static func < (lhs: PlatformTier, rhs: PlatformTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Current Platform Detection
struct Platform {
    static var current: PlatformTier {
        #if os(watchOS)
        return .watchOS
        #elseif os(iOS)
        #if targetEnvironment(macCatalyst)
        return .macOS
        #else
        return UIDevice.current.userInterfaceIdiom == .pad ? .iPadOS : .iOS
        #endif
        #elseif os(macOS)
        return .macOS
        #else
        return .iOS
        #endif
    }
    
    static var isWatch: Bool { current == .watchOS }
    static var isPhone: Bool { current == .iOS }
    static var isTablet: Bool { current == .iPadOS }
    static var isDesktop: Bool { current == .macOS }
}

// MARK: - Platform Capability Matrix
struct PlatformCapability {
    let tier: PlatformTier
    let feature: String
    let enabled: Bool
}

enum CapabilityDomain {
    // MARK: Layout Capabilities
    struct Layout {
        /// Multi-pane layouts (split views, sidebars)
        static var supportsMultiPane: Bool {
            Platform.current >= .iPadOS
        }
        
        /// Persistent sidebars
        static var supportsPersistentSidebar: Bool {
            Platform.current >= .iPadOS
        }
        
        /// Floating panels
        static var supportsFloatingPanels: Bool {
            Platform.current >= .macOS
        }
        
        /// Full-width sheets vs modals
        static var prefersFullWidthSheets: Bool {
            Platform.current == .iOS || Platform.current == .watchOS
        }
        
        /// Navigation depth limit
        static var maxNavigationDepth: Int {
            switch Platform.current {
            case .watchOS: return 2
            case .iOS: return 4
            case .iPadOS: return 6
            case .macOS: return 8
            }
        }
    }
    
    // MARK: Interaction Capabilities
    struct Interaction {
        /// Hover interactions
        static var supportsHover: Bool {
            Platform.current >= .iPadOS
        }
        
        /// Keyboard shortcuts
        static var supportsKeyboardShortcuts: Bool {
            Platform.current >= .iPadOS
        }
        
        /// Context menus (right-click style)
        static var supportsRichContextMenus: Bool {
            Platform.current >= .iPadOS
        }
        
        /// Drag and drop between apps
        static var supportsCrossPlatformDragDrop: Bool {
            Platform.current >= .iPadOS
        }
        
        /// Multiple windows
        static var supportsMultipleWindows: Bool {
            Platform.current >= .iPadOS
        }
        
        /// Pointer precision (fine-grained control)
        static var hasPointerPrecision: Bool {
            Platform.current >= .iPadOS
        }
        
        /// Touch-first (vs pointer-first)
        static var isTouchFirst: Bool {
            Platform.current <= .iPadOS
        }
    }
    
    // MARK: Density Capabilities
    struct Density {
        /// Information density per screen
        static var uiDensity: UIDensity {
            switch Platform.current {
            case .watchOS: return .minimal
            case .iOS: return .standard
            case .iPadOS: return .comfortable
            case .macOS: return .dense
            }
        }
        
        /// Minimum tap target size (points)
        static var minTapTargetSize: CGFloat {
            switch Platform.current {
            case .watchOS: return 44
            case .iOS: return 44
            case .iPadOS: return 40
            case .macOS: return 28
            }
        }
        
        /// Content padding multiplier
        static var paddingScale: CGFloat {
            switch Platform.current {
            case .watchOS: return 0.8
            case .iOS: return 1.0
            case .iPadOS: return 1.2
            case .macOS: return 1.0
            }
        }
    }
    
    // MARK: Visual Capabilities
    struct Visual {
        /// Supports translucent materials
        static var supportsVibrancy: Bool {
            true
        }
        
        /// Supports custom window chrome
        static var supportsCustomWindowChrome: Bool {
            Platform.current == .macOS
        }
        
        /// Menu bar integration
        static var hasMenuBar: Bool {
            Platform.current == .macOS
        }
        
        /// Tab bar vs navigation
        static var prefersTabBar: Bool {
            Platform.current <= .iOS
        }
        
        /// Sidebar vs tab bar
        static var prefersSidebar: Bool {
            Platform.current >= .iPadOS
        }
    }
    
    // MARK: Navigation Capabilities
    struct Navigation {
        /// Supports breadcrumbs
        static var supportsBreadcrumbs: Bool {
            Platform.current >= .macOS
        }
        
        /// Supports persistent navigation history
        static var supportsPersistentHistory: Bool {
            Platform.current >= .iPadOS
        }
        
        /// Back gesture
        static var supportsSwipeBack: Bool {
            Platform.current <= .iPadOS
        }
        
        /// Hierarchical navigation style
        static var navigationStyle: NavigationStyle {
            switch Platform.current {
            case .watchOS: return .stack
            case .iOS: return .stack
            case .iPadOS: return .splitView
            case .macOS: return .sidebar
            }
        }
    }
}

// MARK: - Supporting Types
enum UIDensity {
    case minimal    // watchOS: 1-2 key items
    case standard   // iOS: 3-5 key items
    case comfortable // iPadOS: 5-8 key items
    case dense      // macOS: 10+ items, rich detail
}

enum NavigationStyle {
    case stack      // Push/pop linear navigation
    case splitView  // Two-column navigation
    case sidebar    // Three-column with sidebar
}

// MARK: - Platform-Specific Modifiers
extension View {
    /// Apply platform-appropriate padding
    func platformPadding(_ edges: Edge.Set = .all) -> some View {
        self.padding(edges, CapabilityDomain.Density.paddingScale * 16)
    }
    
    /// Apply platform-appropriate spacing in stacks
    func platformSpacing() -> CGFloat {
        CapabilityDomain.Density.paddingScale * 12
    }
    
    /// Conditional hover effect
    func platformHoverEffect() -> some View {
        Group {
            if CapabilityDomain.Interaction.supportsHover {
                #if os(iOS)
                self.hoverEffect()
                #else
                self
                #endif
            } else {
                self
            }
        }
    }
    
    /// Platform-appropriate context menu
    func platformContextMenu<MenuItems: View>(@ViewBuilder menuItems: () -> MenuItems) -> some View {
        Group {
            if CapabilityDomain.Interaction.supportsRichContextMenus {
                self.contextMenu(menuItems: menuItems)
            } else {
                self
            }
        }
    }
}

// MARK: - Platform Capability Matrix Documentation
/// # Platform Capability Matrix
///
/// ## watchOS (Tier 0)
/// - **Focus**: Glanceable, quick interactions
/// - **Navigation**: Max 2 levels deep
/// - **Layout**: Single-focus, full-screen
/// - **Interaction**: Touch + Digital Crown
/// - **Density**: Minimal (1-2 key items)
///
/// ## iOS (Tier 1)
/// - **Focus**: Single-task, immersive
/// - **Navigation**: Max 4 levels deep, tab bar primary
/// - **Layout**: Single-pane, modal sheets
/// - **Interaction**: Touch-first, swipe gestures
/// - **Density**: Standard (3-5 key items)
/// - **Inheritance**: None (does NOT inherit from iPadOS)
///
/// ## iPadOS (Tier 2)
/// - **Focus**: Flexible productivity
/// - **Navigation**: Max 6 levels deep, sidebar + detail
/// - **Layout**: Multi-pane, split views, floating
/// - **Interaction**: Touch + Pencil + Keyboard + Trackpad
/// - **Density**: Comfortable (5-8 key items)
/// - **Inheritance**: Selective from macOS (keyboard shortcuts, hover)
/// - **Restrictions**: No menu bar metaphors, no mandatory hover-only UI
///
/// ## macOS (Tier 3)
/// - **Focus**: Maximum power and control
/// - **Navigation**: Max 8 levels deep, sidebar + navigation
/// - **Layout**: Multi-window, multi-pane, floating panels
/// - **Interaction**: Pointer-first + Keyboard
/// - **Density**: Dense (10+ items, rich detail)
/// - **Features**: Menu bar, window management, full keyboard control
///
/// ## Design Principles
/// 1. **One Visual Language**: Shared color, typography, spacing tokens
/// 2. **Platform-Appropriate Density**: More capable = more dense
/// 3. **Predictable Behavior**: Same feature works similarly across platforms
/// 4. **No Lesser Clones**: Each platform is optimized for its strengths
///
/// ## Anti-Patterns
/// - ❌ iPadOS as macOS clone
/// - ❌ iOS inheriting iPadOS complexity
/// - ❌ Desktop paradigms on touch devices
/// - ❌ Forced feature parity across all platforms
/// - ❌ watchOS with deep navigation
struct PlatformCapabilityMatrix {
    static func printMatrix() {
        print("""
        
        PLATFORM CAPABILITY MATRIX
        ==========================
        
        Layout:
          Multi-pane:          \(Platform.isTablet || Platform.isDesktop ? "✓" : "✗")
          Persistent sidebar:  \(CapabilityDomain.Layout.supportsPersistentSidebar ? "✓" : "✗")
          Floating panels:     \(CapabilityDomain.Layout.supportsFloatingPanels ? "✓" : "✗")
          Max nav depth:       \(CapabilityDomain.Layout.maxNavigationDepth)
        
        Interaction:
          Hover:               \(CapabilityDomain.Interaction.supportsHover ? "✓" : "✗")
          Keyboard shortcuts:  \(CapabilityDomain.Interaction.supportsKeyboardShortcuts ? "✓" : "✗")
          Rich context menus:  \(CapabilityDomain.Interaction.supportsRichContextMenus ? "✓" : "✗")
          Multiple windows:    \(CapabilityDomain.Interaction.supportsMultipleWindows ? "✓" : "✗")
          Pointer precision:   \(CapabilityDomain.Interaction.hasPointerPrecision ? "✓" : "✗")
          Touch-first:         \(CapabilityDomain.Interaction.isTouchFirst ? "✓" : "✗")
        
        Density:
          UI Density:          \(CapabilityDomain.Density.uiDensity)
          Min tap target:      \(CapabilityDomain.Density.minTapTargetSize)pt
          Padding scale:       \(CapabilityDomain.Density.paddingScale)x
        
        Visual:
          Menu bar:            \(CapabilityDomain.Visual.hasMenuBar ? "✓" : "✗")
          Custom chrome:       \(CapabilityDomain.Visual.supportsCustomWindowChrome ? "✓" : "✗")
          Prefers tab bar:     \(CapabilityDomain.Visual.prefersTabBar ? "✓" : "✗")
          Prefers sidebar:     \(CapabilityDomain.Visual.prefersSidebar ? "✓" : "✗")
        
        Navigation:
          Breadcrumbs:         \(CapabilityDomain.Navigation.supportsBreadcrumbs ? "✓" : "✗")
          Swipe back:          \(CapabilityDomain.Navigation.supportsSwipeBack ? "✓" : "✗")
          Style:               \(CapabilityDomain.Navigation.navigationStyle)
        
        Current Platform:      \(Platform.current)
        """)
    }
}
