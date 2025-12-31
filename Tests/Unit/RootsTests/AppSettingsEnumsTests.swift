//
//  AppSettingsEnumsTests.swift
//  RootsTests
//
//  Tests for AppSettings enums - TabBarMode, InterfaceStyle, etc.
//

import XCTest
@testable import Roots

@MainActor
final class AppSettingsEnumsTests: BaseTestCase {
    
    // MARK: - TabBarMode Tests
    
    func testTabBarModeAllCases() {
        XCTAssertEqual(TabBarMode.allCases.count, 3)
        XCTAssertTrue(TabBarMode.allCases.contains(.iconsOnly))
        XCTAssertTrue(TabBarMode.allCases.contains(.textOnly))
        XCTAssertTrue(TabBarMode.allCases.contains(.iconsAndText))
    }
    
    func testTabBarModeLabels() {
        XCTAssertEqual(TabBarMode.iconsOnly.label, "Icons")
        XCTAssertEqual(TabBarMode.textOnly.label, "Text")
        XCTAssertEqual(TabBarMode.iconsAndText.label, "Icons & Text")
    }
    
    func testTabBarModeSystemImages() {
        XCTAssertEqual(TabBarMode.iconsOnly.systemImageName, "square.grid.2x2")
        XCTAssertEqual(TabBarMode.textOnly.systemImageName, "textformat")
        XCTAssertEqual(TabBarMode.iconsAndText.systemImageName, "square.grid.2x2.and.square")
    }
    
    func testTabBarModeIdentifiable() {
        XCTAssertEqual(TabBarMode.iconsOnly.id, "iconsOnly")
        XCTAssertEqual(TabBarMode.textOnly.id, "textOnly")
        XCTAssertEqual(TabBarMode.iconsAndText.id, "iconsAndText")
    }
    
    // MARK: - IconLabelMode Alias Tests
    
    func testIconLabelModeDescription() {
        let mode: IconLabelMode = .iconsAndText
        XCTAssertEqual(mode.description, "Icons & Text")
    }
    
    // MARK: - InterfaceStyle Tests
    
    func testInterfaceStyleAllCases() {
        XCTAssertEqual(InterfaceStyle.allCases.count, 4)
        XCTAssertTrue(InterfaceStyle.allCases.contains(.system))
        XCTAssertTrue(InterfaceStyle.allCases.contains(.light))
        XCTAssertTrue(InterfaceStyle.allCases.contains(.dark))
        XCTAssertTrue(InterfaceStyle.allCases.contains(.auto))
    }
    
    func testInterfaceStyleLabels() {
        XCTAssertEqual(InterfaceStyle.light.label, "Light")
        XCTAssertEqual(InterfaceStyle.dark.label, "Dark")
        XCTAssertTrue(InterfaceStyle.system.label.contains("System") || InterfaceStyle.system.label.contains("macOS"))
        XCTAssertEqual(InterfaceStyle.auto.label, "Automatic at Night")
    }
    
    func testInterfaceStyleIdentifiable() {
        XCTAssertEqual(InterfaceStyle.system.id, "system")
        XCTAssertEqual(InterfaceStyle.light.id, "light")
        XCTAssertEqual(InterfaceStyle.dark.id, "dark")
        XCTAssertEqual(InterfaceStyle.auto.id, "auto")
    }
    
    // MARK: - SidebarBehavior Tests
    
    func testSidebarBehaviorAllCases() {
        XCTAssertEqual(SidebarBehavior.allCases.count, 3)
        XCTAssertTrue(SidebarBehavior.allCases.contains(.automatic))
        XCTAssertTrue(SidebarBehavior.allCases.contains(.expanded))
        XCTAssertTrue(SidebarBehavior.allCases.contains(.compact))
    }
    
    func testSidebarBehaviorLabels() {
        XCTAssertEqual(SidebarBehavior.automatic.label, "Auto-collapse")
        XCTAssertEqual(SidebarBehavior.expanded.label, "Always expanded")
        XCTAssertEqual(SidebarBehavior.compact.label, "Favor compact mode")
    }
    
    func testSidebarBehaviorIdentifiable() {
        XCTAssertEqual(SidebarBehavior.automatic.id, "automatic")
        XCTAssertEqual(SidebarBehavior.expanded.id, "expanded")
        XCTAssertEqual(SidebarBehavior.compact.id, "compact")
    }
    
    // MARK: - CardRadius Tests
    
    func testCardRadiusAllCases() {
        XCTAssertEqual(CardRadius.allCases.count, 3)
        XCTAssertTrue(CardRadius.allCases.contains(.small))
        XCTAssertTrue(CardRadius.allCases.contains(.medium))
        XCTAssertTrue(CardRadius.allCases.contains(.large))
    }
    
    func testCardRadiusLabels() {
        XCTAssertEqual(CardRadius.small.label, "Small")
        XCTAssertEqual(CardRadius.medium.label, "Medium")
        XCTAssertEqual(CardRadius.large.label, "Large")
    }
    
    func testCardRadiusValues() {
        XCTAssertEqual(CardRadius.small.value, 12)
        XCTAssertEqual(CardRadius.medium.value, 18)
        XCTAssertEqual(CardRadius.large.value, 26)
    }
    
    func testCardRadiusIdentifiable() {
        XCTAssertEqual(CardRadius.small.id, "small")
        XCTAssertEqual(CardRadius.medium.id, "medium")
        XCTAssertEqual(CardRadius.large.id, "large")
    }
    
    // MARK: - Ordering Tests
    
    func testCardRadiusValueOrdering() {
        XCTAssertLessThan(CardRadius.small.value, CardRadius.medium.value)
        XCTAssertLessThan(CardRadius.medium.value, CardRadius.large.value)
    }
    
    // MARK: - RawValue Tests
    
    func testTabBarModeRawValues() {
        XCTAssertEqual(TabBarMode.iconsOnly.rawValue, "iconsOnly")
        XCTAssertEqual(TabBarMode.textOnly.rawValue, "textOnly")
        XCTAssertEqual(TabBarMode.iconsAndText.rawValue, "iconsAndText")
    }
    
    func testInterfaceStyleRawValues() {
        XCTAssertEqual(InterfaceStyle.system.rawValue, "system")
        XCTAssertEqual(InterfaceStyle.light.rawValue, "light")
        XCTAssertEqual(InterfaceStyle.dark.rawValue, "dark")
        XCTAssertEqual(InterfaceStyle.auto.rawValue, "auto")
    }
    
    // MARK: - CaseIterable Tests
    
    func testAllEnumsAreCaseIterable() {
        XCTAssertFalse(TabBarMode.allCases.isEmpty)
        XCTAssertFalse(InterfaceStyle.allCases.isEmpty)
        XCTAssertFalse(SidebarBehavior.allCases.isEmpty)
        XCTAssertFalse(CardRadius.allCases.isEmpty)
    }
}
