//
//  MockBiometricAuth.swift
//  ItoriTests
//
//  Created for Phase 6.3: Biometric Auth Testing
//

import Foundation
import LocalAuthentication
@testable import Roots

enum MockBiometricError: Error {
    case notAvailable
    case authenticationFailed
    case userCancel
    case systemCancel
    case passcodeNotSet
    case biometryNotEnrolled
}

enum BiometricType {
    case none
    case touchID
    case faceID
}

class MockBiometricAuth {
    var isAvailable = true
    var biometricType: BiometricType = .faceID
    var shouldSucceed = true
    var failureError: MockBiometricError = .authenticationFailed
    var evaluateCallCount = 0
    var canEvaluateCallCount = 0
    
    func canEvaluateBiometric() -> (Bool, BiometricType) {
        canEvaluateCallCount += 1
        return (isAvailable, biometricType)
    }
    
    func evaluatePolicy(reason: String) async throws -> Bool {
        evaluateCallCount += 1
        
        if !isAvailable {
            throw MockBiometricError.notAvailable
        }
        
        if biometricType == .none {
            throw MockBiometricError.biometryNotEnrolled
        }
        
        if !shouldSucceed {
            throw failureError
        }
        
        return true
    }
    
    func reset() {
        isAvailable = true
        biometricType = .faceID
        shouldSucceed = true
        evaluateCallCount = 0
        canEvaluateCallCount = 0
    }
}
