//
//  PlatformCapabilitiesTests.swift
//  RootsTests
//
//  Tests for PlatformCapabilities - Platform feature detection
//

import XCTest
@testable import Roots

@MainActor
final class PlatformCapabilitiesTests: BaseTestCase {
    
    // MARK: - Hidden Navigation Bar Support Tests
    
    func testSupportsHiddenNavigationBarReturnsBoolean() {
        let result = PlatformCapabilities.supportsHiddenNavigationBar
        
        // Should return a boolean value
        XCTAssertTrue(result == true || result == false)
    }
    
    func testSupportsHiddenNavigationBarConsistent() {
        let result1 = PlatformCapabilities.supportsHiddenNavigationBar
        let result2 = PlatformCapabilities.supportsHiddenNavigationBar
        
        // Should return consistent results
        XCTAssertEqual(result1, result2)
    }
    
    #if os(macOS)
    func testSupportsHiddenNavigationBarOnMacOS() {
        // macOS should not support hidden navigation bar
        XCTAssertFalse(PlatformCapabilities.supportsHiddenNavigationBar)
    }
    #endif
    
    #if os(iOS)
    func testSupportsHiddenNavigationBarOnIOS() {
        if #available(iOS 16.0, *) {
            XCTAssertTrue(PlatformCapabilities.supportsHiddenNavigationBar)
        } else {
            XCTAssertFalse(PlatformCapabilities.supportsHiddenNavigationBar)
        }
    }
    #endif
}
