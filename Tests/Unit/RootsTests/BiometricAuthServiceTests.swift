//
//  BiometricAuthServiceTests.swift
//  RootsTests
//
//  Phase 6.3: Biometric Auth Testing
//

import XCTest
@testable import Roots

final class BiometricAuthServiceTests: XCTestCase {
    var mockAuth: MockBiometricAuth!
    
    override func setUp() {
        super.setUp()
        mockAuth = MockBiometricAuth()
    }
    
    override func tearDown() {
        mockAuth = nil
        super.tearDown()
    }
    
    // MARK: - Availability Tests
    
    func testBiometricAvailable() {
        let (available, type) = mockAuth.canEvaluateBiometric()
        
        XCTAssertTrue(available)
        XCTAssertEqual(type, .faceID)
        XCTAssertEqual(mockAuth.canEvaluateCallCount, 1)
    }
    
    func testBiometricNotAvailable() {
        mockAuth.isAvailable = false
        
        let (available, _) = mockAuth.canEvaluateBiometric()
        
        XCTAssertFalse(available)
    }
    
    func testFaceIDDetection() {
        mockAuth.biometricType = .faceID
        
        let (_, type) = mockAuth.canEvaluateBiometric()
        
        XCTAssertEqual(type, .faceID)
    }
    
    func testTouchIDDetection() {
        mockAuth.biometricType = .touchID
        
        let (_, type) = mockAuth.canEvaluateBiometric()
        
        XCTAssertEqual(type, .touchID)
    }
    
    func testNoBiometricEnrolled() {
        mockAuth.biometricType = .none
        
        let (available, type) = mockAuth.canEvaluateBiometric()
        
        XCTAssertTrue(available)
        XCTAssertEqual(type, .none)
    }
    
    // MARK: - Authentication Tests
    
    func testSuccessfulAuthentication() async throws {
        let result = try await mockAuth.evaluatePolicy(reason: "Test authentication")
        
        XCTAssertTrue(result)
        XCTAssertEqual(mockAuth.evaluateCallCount, 1)
    }
    
    func testAuthenticationFailure() async {
        mockAuth.shouldSucceed = false
        mockAuth.failureError = .authenticationFailed
        
        do {
            _ = try await mockAuth.evaluatePolicy(reason: "Test")
            XCTFail("Should have thrown authentication error")
        } catch MockBiometricError.authenticationFailed {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testUserCancelAuthentication() async {
        mockAuth.shouldSucceed = false
        mockAuth.failureError = .userCancel
        
        do {
            _ = try await mockAuth.evaluatePolicy(reason: "Test")
            XCTFail("Should have thrown user cancel error")
        } catch MockBiometricError.userCancel {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testSystemCancelAuthentication() async {
        mockAuth.shouldSucceed = false
        mockAuth.failureError = .systemCancel
        
        do {
            _ = try await mockAuth.evaluatePolicy(reason: "Test")
            XCTFail("Should have thrown system cancel error")
        } catch MockBiometricError.systemCancel {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testAuthWhenNotAvailable() async {
        mockAuth.isAvailable = false
        
        do {
            _ = try await mockAuth.evaluatePolicy(reason: "Test")
            XCTFail("Should have thrown not available error")
        } catch MockBiometricError.notAvailable {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testAuthWhenBiometryNotEnrolled() async {
        mockAuth.biometricType = .none
        
        do {
            _ = try await mockAuth.evaluatePolicy(reason: "Test")
            XCTFail("Should have thrown not enrolled error")
        } catch MockBiometricError.biometryNotEnrolled {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testPasscodeNotSet() async {
        mockAuth.shouldSucceed = false
        mockAuth.failureError = .passcodeNotSet
        
        do {
            _ = try await mockAuth.evaluatePolicy(reason: "Test")
            XCTFail("Should have thrown passcode not set error")
        } catch MockBiometricError.passcodeNotSet {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    // MARK: - Multiple Authentication Tests
    
    func testMultipleSuccessfulAuthentications() async throws {
        _ = try await mockAuth.evaluatePolicy(reason: "First")
        _ = try await mockAuth.evaluatePolicy(reason: "Second")
        _ = try await mockAuth.evaluatePolicy(reason: "Third")
        
        XCTAssertEqual(mockAuth.evaluateCallCount, 3)
    }
    
    func testAlternatingSuccessFailure() async {
        // First succeeds
        mockAuth.shouldSucceed = true
        _ = try? await mockAuth.evaluatePolicy(reason: "Test")
        
        // Second fails
        mockAuth.shouldSucceed = false
        do {
            _ = try await mockAuth.evaluatePolicy(reason: "Test")
            XCTFail("Should have failed")
        } catch {
            // Expected
        }
        
        // Third succeeds
        mockAuth.shouldSucceed = true
        _ = try? await mockAuth.evaluatePolicy(reason: "Test")
        
        XCTAssertEqual(mockAuth.evaluateCallCount, 3)
    }
    
    // MARK: - Reset Tests
    
    func testReset() {
        mockAuth.isAvailable = false
        mockAuth.biometricType = .touchID
        mockAuth.shouldSucceed = false
        mockAuth.evaluateCallCount = 5
        mockAuth.canEvaluateCallCount = 3
        
        mockAuth.reset()
        
        XCTAssertTrue(mockAuth.isAvailable)
        XCTAssertEqual(mockAuth.biometricType, .faceID)
        XCTAssertTrue(mockAuth.shouldSucceed)
        XCTAssertEqual(mockAuth.evaluateCallCount, 0)
        XCTAssertEqual(mockAuth.canEvaluateCallCount, 0)
    }
}
