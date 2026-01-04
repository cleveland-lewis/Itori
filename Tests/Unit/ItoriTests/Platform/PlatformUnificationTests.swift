import XCTest
#if canImport(SharedCore)
@testable import SharedCore

final class PlatformUnificationTests: XCTestCase {
    
    // MARK: - Platform Detection Tests
    
    func testPlatformTierComparison() {
        XCTAssertTrue(PlatformTier.watchOS < PlatformTier.iOS)
        XCTAssertTrue(PlatformTier.iOS < PlatformTier.iPadOS)
        XCTAssertTrue(PlatformTier.iPadOS < PlatformTier.macOS)
        XCTAssertFalse(PlatformTier.macOS < PlatformTier.watchOS)
    }
    
    func testCurrentPlatformIsValid() {
        let current = Platform.current
        XCTAssertTrue([.watchOS, .iOS, .iPadOS, .macOS].contains(current))
    }
    
    func testOnlyOnePlatformBoolIsTrue() {
        let bools = [Platform.isWatch, Platform.isPhone, Platform.isTablet, Platform.isDesktop]
        let trueCount = bools.filter { $0 }.count
        XCTAssertEqual(trueCount, 1, "Exactly one platform detection bool should be true")
    }
    
    // MARK: - Layout Capability Tests
    
    func testMultiPaneOnlyOnHigherTiers() {
        if Platform.current >= .iPadOS {
            XCTAssertTrue(CapabilityDomain.Layout.supportsMultiPane)
        } else {
            XCTAssertFalse(CapabilityDomain.Layout.supportsMultiPane)
        }
    }
    
    func testPersistentSidebarOnlyOnHigherTiers() {
        if Platform.current >= .iPadOS {
            XCTAssertTrue(CapabilityDomain.Layout.supportsPersistentSidebar)
        } else {
            XCTAssertFalse(CapabilityDomain.Layout.supportsPersistentSidebar)
        }
    }
    
    func testFloatingPanelsOnlyOnMacOS() {
        if Platform.current == .macOS {
            XCTAssertTrue(CapabilityDomain.Layout.supportsFloatingPanels)
        } else {
            XCTAssertFalse(CapabilityDomain.Layout.supportsFloatingPanels)
        }
    }
    
    func testNavigationDepthIncreasesWithTier() {
        let depth = CapabilityDomain.Layout.maxNavigationDepth
        
        switch Platform.current {
        case .watchOS:
            XCTAssertEqual(depth, 2)
        case .iOS:
            XCTAssertEqual(depth, 4)
        case .iPadOS:
            XCTAssertEqual(depth, 6)
        case .macOS:
            XCTAssertEqual(depth, 8)
        }
    }
    
    func testFullWidthSheetsOnLowerTiers() {
        if Platform.current <= .iOS {
            XCTAssertTrue(CapabilityDomain.Layout.prefersFullWidthSheets)
        } else {
            XCTAssertFalse(CapabilityDomain.Layout.prefersFullWidthSheets)
        }
    }
    
    // MARK: - Interaction Capability Tests
    
    func testHoverOnlyOnHigherTiers() {
        if Platform.current >= .iPadOS {
            XCTAssertTrue(CapabilityDomain.Interaction.supportsHover)
        } else {
            XCTAssertFalse(CapabilityDomain.Interaction.supportsHover)
        }
    }
    
    func testKeyboardShortcutsOnlyOnHigherTiers() {
        if Platform.current >= .iPadOS {
            XCTAssertTrue(CapabilityDomain.Interaction.supportsKeyboardShortcuts)
        } else {
            XCTAssertFalse(CapabilityDomain.Interaction.supportsKeyboardShortcuts)
        }
    }
    
    func testRichContextMenusOnlyOnHigherTiers() {
        if Platform.current >= .iPadOS {
            XCTAssertTrue(CapabilityDomain.Interaction.supportsRichContextMenus)
        } else {
            XCTAssertFalse(CapabilityDomain.Interaction.supportsRichContextMenus)
        }
    }
    
    func testMultipleWindowsOnlyOnHigherTiers() {
        if Platform.current >= .iPadOS {
            XCTAssertTrue(CapabilityDomain.Interaction.supportsMultipleWindows)
        } else {
            XCTAssertFalse(CapabilityDomain.Interaction.supportsMultipleWindows)
        }
    }
    
    func testPointerPrecisionOnlyOnHigherTiers() {
        if Platform.current >= .iPadOS {
            XCTAssertTrue(CapabilityDomain.Interaction.hasPointerPrecision)
        } else {
            XCTAssertFalse(CapabilityDomain.Interaction.hasPointerPrecision)
        }
    }
    
    func testTouchFirstOnLowerTiers() {
        if Platform.current <= .iPadOS {
            XCTAssertTrue(CapabilityDomain.Interaction.isTouchFirst)
        } else {
            XCTAssertFalse(CapabilityDomain.Interaction.isTouchFirst)
        }
    }
    
    // MARK: - Density Capability Tests
    
    func testDensityIncreasesWithTier() {
        let density = CapabilityDomain.Density.uiDensity
        
        switch Platform.current {
        case .watchOS:
            XCTAssertEqual(density, .minimal)
        case .iOS:
            XCTAssertEqual(density, .standard)
        case .iPadOS:
            XCTAssertEqual(density, .comfortable)
        case .macOS:
            XCTAssertEqual(density, .dense)
        }
    }
    
    func testTapTargetSizeIsValid() {
        let size = CapabilityDomain.Density.minTapTargetSize
        
        switch Platform.current {
        case .watchOS:
            XCTAssertEqual(size, 44)
        case .iOS:
            XCTAssertEqual(size, 44)
        case .iPadOS:
            XCTAssertEqual(size, 40)
        case .macOS:
            XCTAssertEqual(size, 28)
        }
        
        XCTAssertGreaterThan(size, 20, "Tap target must be reasonable size")
    }
    
    func testPaddingScaleIsValid() {
        let scale = CapabilityDomain.Density.paddingScale
        XCTAssertGreaterThan(scale, 0)
        XCTAssertLessThan(scale, 2)
    }
    
    // MARK: - Visual Capability Tests
    
    func testMenuBarOnlyOnMacOS() {
        if Platform.current == .macOS {
            XCTAssertTrue(CapabilityDomain.Visual.hasMenuBar)
        } else {
            XCTAssertFalse(CapabilityDomain.Visual.hasMenuBar)
        }
    }
    
    func testCustomWindowChromeOnlyOnMacOS() {
        if Platform.current == .macOS {
            XCTAssertTrue(CapabilityDomain.Visual.supportsCustomWindowChrome)
        } else {
            XCTAssertFalse(CapabilityDomain.Visual.supportsCustomWindowChrome)
        }
    }
    
    func testTabBarOnLowerTiers() {
        if Platform.current <= .iOS {
            XCTAssertTrue(CapabilityDomain.Visual.prefersTabBar)
        } else {
            XCTAssertFalse(CapabilityDomain.Visual.prefersTabBar)
        }
    }
    
    func testSidebarOnHigherTiers() {
        if Platform.current >= .iPadOS {
            XCTAssertTrue(CapabilityDomain.Visual.prefersSidebar)
        } else {
            XCTAssertFalse(CapabilityDomain.Visual.prefersSidebar)
        }
    }
    
    // MARK: - Navigation Capability Tests
    
    func testBreadcrumbsOnlyOnMacOS() {
        if Platform.current == .macOS {
            XCTAssertTrue(CapabilityDomain.Navigation.supportsBreadcrumbs)
        } else {
            XCTAssertFalse(CapabilityDomain.Navigation.supportsBreadcrumbs)
        }
    }
    
    func testSwipeBackOnLowerTiers() {
        if Platform.current <= .iPadOS {
            XCTAssertTrue(CapabilityDomain.Navigation.supportsSwipeBack)
        } else {
            XCTAssertFalse(CapabilityDomain.Navigation.supportsSwipeBack)
        }
    }
    
    func testNavigationStyleMatchesPlatform() {
        let style = CapabilityDomain.Navigation.navigationStyle
        
        switch Platform.current {
        case .watchOS, .iOS:
            XCTAssertEqual(style, .stack)
        case .iPadOS:
            XCTAssertEqual(style, .splitView)
        case .macOS:
            XCTAssertEqual(style, .sidebar)
        }
    }
    
    // MARK: - Anti-Pattern Detection Tests
    
    func testIPadOSNotActingAsMacOS() {
        if Platform.current == .iPadOS {
            XCTAssertFalse(AntiPatterns.detectIPadOSAsMacOSClone(),
                          "iPadOS should not have menu bar or window chrome")
        }
    }
    
    func testIOSNotInheritingIPadOSComplexity() {
        if Platform.current == .iOS {
            XCTAssertFalse(AntiPatterns.detectIOSInheritingIPadOSComplexity(),
                          "iOS should not have multi-pane layouts or sidebar")
        }
    }
    
    func testWatchOSNavigationDepth() {
        if Platform.current == .watchOS {
            XCTAssertFalse(AntiPatterns.detectWatchOSDeepNavigation(),
                          "watchOS navigation depth should be ≤ 2")
        }
    }
    
    // MARK: - Platform Validation Tests
    
    func testPlatformValidation() {
        let errors = PlatformValidation.validate()
        
        // Should have no validation errors
        XCTAssertTrue(errors.isEmpty,
                     "Platform validation should pass. Errors: \(errors.map { $0.description })")
    }
    
    // MARK: - Feature Flag Tests
    
    func testMultiWindowFeatureFlag() {
        let isEnabled = PlatformFeature.isEnabled(.multiWindow)
        XCTAssertEqual(isEnabled, CapabilityDomain.Interaction.supportsMultipleWindows)
    }
    
    func testKeyboardShortcutsFeatureFlag() {
        let isEnabled = PlatformFeature.isEnabled(.keyboardShortcuts)
        XCTAssertEqual(isEnabled, CapabilityDomain.Interaction.supportsKeyboardShortcuts)
    }
    
    func testHoverEffectsFeatureFlag() {
        let isEnabled = PlatformFeature.isEnabled(.hoverEffects)
        XCTAssertEqual(isEnabled, CapabilityDomain.Interaction.supportsHover)
    }
    
    func testSplitViewFeatureFlag() {
        let isEnabled = PlatformFeature.isEnabled(.splitView)
        XCTAssertEqual(isEnabled, CapabilityDomain.Layout.supportsMultiPane)
    }
    
    func testMenuBarFeatureFlag() {
        let isEnabled = PlatformFeature.isEnabled(.menuBar)
        XCTAssertEqual(isEnabled, CapabilityDomain.Visual.hasMenuBar)
    }
    
    // MARK: - Guideline Tests
    
    func testWatchOSGuidelines() {
        if Platform.current == .watchOS {
            XCTAssertEqual(WatchOSGuidelines.maxNavigationDepth, 2)
            XCTAssertEqual(WatchOSGuidelines.minTapTarget, 44)
            XCTAssertEqual(WatchOSGuidelines.cardCornerRadius, 8)
        }
    }
    
    func testIOSGuidelines() {
        if Platform.current == .iOS {
            XCTAssertEqual(IOSGuidelines.maxNavigationDepth, 4)
            XCTAssertEqual(IOSGuidelines.minTapTarget, 44)
            XCTAssertEqual(IOSGuidelines.cardCornerRadius, 12)
        }
    }
    
    func testIPadOSGuidelines() {
        if Platform.current == .iPadOS {
            XCTAssertEqual(IPadOSGuidelines.maxNavigationDepth, 6)
            XCTAssertEqual(IPadOSGuidelines.minTapTarget, 40)
            XCTAssertEqual(IPadOSGuidelines.cardCornerRadius, 16)
        }
    }
    
    func testMacOSGuidelines() {
        if Platform.current == .macOS {
            XCTAssertEqual(MacOSGuidelines.maxNavigationDepth, 8)
            XCTAssertEqual(MacOSGuidelines.minClickTarget, 28)
            XCTAssertEqual(MacOSGuidelines.cardCornerRadius, 12)
        }
    }
    
    // MARK: - Cross-Platform Rules Tests
    
    func testVisualLanguageConsistency() {
        XCTAssertTrue(CrossPlatformRules.VisualLanguage.useSharedColors)
        XCTAssertTrue(CrossPlatformRules.VisualLanguage.useSharedTypography)
        XCTAssertTrue(CrossPlatformRules.VisualLanguage.useSharedIcons)
    }
    
    func testBehavioralConsistency() {
        XCTAssertTrue(CrossPlatformRules.Behavior.consistentFeatureBehavior)
        XCTAssertTrue(CrossPlatformRules.Behavior.sharedDataModel)
        XCTAssertTrue(CrossPlatformRules.Behavior.visibleSyncState)
        XCTAssertTrue(CrossPlatformRules.Behavior.consistentErrorHandling)
    }
    
    func testPlatformDifferentiation() {
        XCTAssertTrue(CrossPlatformRules.Differentiation.respectPlatformIdioms)
        XCTAssertTrue(CrossPlatformRules.Differentiation.allowFeatureDifferences)
        XCTAssertTrue(CrossPlatformRules.Differentiation.platformOptimization)
        XCTAssertTrue(CrossPlatformRules.Differentiation.noLesserClones)
    }
    
    // MARK: - Integration Tests
    
    func testCapabilitiesAreCoherent() {
        // If supports multi-pane, should also support persistent sidebar
        if CapabilityDomain.Layout.supportsMultiPane {
            XCTAssertTrue(CapabilityDomain.Layout.supportsPersistentSidebar)
        }
        
        // If has pointer precision, should support hover
        if CapabilityDomain.Interaction.hasPointerPrecision {
            XCTAssertTrue(CapabilityDomain.Interaction.supportsHover)
        }
        
        // If has menu bar, should support keyboard shortcuts
        if CapabilityDomain.Visual.hasMenuBar {
            XCTAssertTrue(CapabilityDomain.Interaction.supportsKeyboardShortcuts)
        }
    }
    
    func testNavigationDepthNeverExceedsGuideline() {
        let actualDepth = CapabilityDomain.Layout.maxNavigationDepth
        
        switch Platform.current {
        case .watchOS:
            XCTAssertLessThanOrEqual(actualDepth, WatchOSGuidelines.maxNavigationDepth)
        case .iOS:
            XCTAssertLessThanOrEqual(actualDepth, IOSGuidelines.maxNavigationDepth)
        case .iPadOS:
            XCTAssertLessThanOrEqual(actualDepth, IPadOSGuidelines.maxNavigationDepth)
        case .macOS:
            XCTAssertLessThanOrEqual(actualDepth, MacOSGuidelines.maxNavigationDepth)
        }
    }
}
#endif
