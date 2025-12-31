//
//  AnimationPolicyTests.swift
//  RootsTests
//
//  Tests for AnimationPolicy - Accessibility-aware animation management
//

import XCTest
import SwiftUI
@testable import Roots

@MainActor
final class AnimationPolicyTests: BaseTestCase {
    
    var policy: AnimationPolicy!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        policy = AnimationPolicy.shared
    }
    
    override func tearDownWithError() throws {
        policy = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Animation Context Tests
    
    func testAnimationContextAllCases() {
        let contexts: [AnimationPolicy.AnimationContext] = [
            .essential, .decorative, .chart, .continuous, .navigation, .listTransition
        ]
        XCTAssertEqual(contexts.count, 6)
    }
    
    // MARK: - Duration Tests
    
    func testDurationEssential() {
        let duration = policy.duration(for: .essential)
        XCTAssertEqual(duration, 0.25)
    }
    
    func testDurationDecorative() {
        let duration = policy.duration(for: .decorative)
        XCTAssertEqual(duration, 0.35)
    }
    
    func testDurationChart() {
        let duration = policy.duration(for: .chart)
        XCTAssertEqual(duration, 0.8)
    }
    
    func testDurationContinuous() {
        let duration = policy.duration(for: .continuous)
        XCTAssertEqual(duration, 1.5)
    }
    
    func testDurationNavigation() {
        let duration = policy.duration(for: .navigation)
        XCTAssertEqual(duration, 0.3)
    }
    
    func testDurationListTransition() {
        let duration = policy.duration(for: .listTransition)
        XCTAssertEqual(duration, 0.4)
    }
    
    // MARK: - Should Animate Tests
    
    func testShouldAnimateWhenReduceMotionDisabled() {
        // Assuming reduce motion is disabled by default
        for context in [AnimationPolicy.AnimationContext.essential, .decorative, .chart, .continuous, .navigation, .listTransition] {
            XCTAssertTrue(policy.shouldAnimate(for: context))
        }
    }
    
    // MARK: - Animation Retrieval Tests
    
    func testAnimationForEssential() {
        let animation = policy.animation(for: .essential)
        XCTAssertNotNil(animation)
    }
    
    func testAnimationForDecorative() {
        let animation = policy.animation(for: .decorative)
        XCTAssertNotNil(animation)
    }
    
    func testAnimationForChart() {
        let animation = policy.animation(for: .chart)
        XCTAssertNotNil(animation)
    }
    
    func testAnimationForContinuous() {
        let animation = policy.animation(for: .continuous)
        XCTAssertNotNil(animation)
    }
    
    func testAnimationForNavigation() {
        let animation = policy.animation(for: .navigation)
        XCTAssertNotNil(animation)
    }
    
    func testAnimationForListTransition() {
        let animation = policy.animation(for: .listTransition)
        XCTAssertNotNil(animation)
    }
    
    // MARK: - WithAnimation Tests
    
    func testWithAnimationExecutesBlock() {
        var executed = false
        
        policy.withAnimation(.essential) {
            executed = true
        }
        
        XCTAssertTrue(executed)
    }
    
    func testWithAnimationReturnsValue() {
        let result = policy.withAnimation(.essential) {
            return 42
        }
        
        XCTAssertEqual(result, 42)
    }
    
    func testWithAnimationThrowsErrors() {
        struct TestError: Error {}
        
        XCTAssertThrowsError(
            try policy.withAnimation(.essential) {
                throw TestError()
            }
        )
    }
    
    // MARK: - Published Property Tests
    
    func testIsReduceMotionEnabledPublished() {
        XCTAssertNotNil(policy.$isReduceMotionEnabled)
    }
    
    // MARK: - Context Consistency Tests
    
    func testAllContextsHaveDefinedDuration() {
        let contexts: [AnimationPolicy.AnimationContext] = [
            .essential, .decorative, .chart, .continuous, .navigation, .listTransition
        ]
        
        for context in contexts {
            let duration = policy.duration(for: context)
            XCTAssertGreaterThanOrEqual(duration, 0.0)
        }
    }
    
    func testAllContextsHaveDefinedShouldAnimate() {
        let contexts: [AnimationPolicy.AnimationContext] = [
            .essential, .decorative, .chart, .continuous, .navigation, .listTransition
        ]
        
        for context in contexts {
            // Should not crash
            _ = policy.shouldAnimate(for: context)
        }
    }
    
    // MARK: - Update Tests
    
    func testUpdateFromAppSettings() {
        // Should not crash
        policy.updateFromAppSettings()
        XCTAssertTrue(true)
    }
}
