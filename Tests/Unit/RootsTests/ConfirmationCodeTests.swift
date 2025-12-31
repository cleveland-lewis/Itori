//
//  ConfirmationCodeTests.swift
//  RootsTests
//
//  Tests for ConfirmationCode - Confirmation code generation
//

import XCTest
@testable import Roots

@MainActor
final class ConfirmationCodeTests: BaseTestCase {
    
    // MARK: - Generation Tests
    
    func testGenerateReturnsNonEmpty() {
        let code = ConfirmationCode.generate()
        
        XCTAssertFalse(code.isEmpty)
    }
    
    func testGenerateFormat() {
        let code = ConfirmationCode.generate()
        
        // Expected format: XXXX-XXXX (4 chars, dash, 4 chars)
        XCTAssertEqual(code.count, 9) // 4 + 1 + 4
        XCTAssertTrue(code.contains("-"))
    }
    
    func testGenerateFormatPattern() {
        let code = ConfirmationCode.generate()
        let components = code.split(separator: "-")
        
        XCTAssertEqual(components.count, 2)
        XCTAssertEqual(components[0].count, 4)
        XCTAssertEqual(components[1].count, 4)
    }
    
    func testGenerateUsesValidCharacters() {
        let validChars = Set("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
        let code = ConfirmationCode.generate()
        
        let codeChars = Set(code.replacingOccurrences(of: "-", with: ""))
        XCTAssertTrue(codeChars.isSubset(of: validChars))
    }
    
    func testGenerateExcludesAmbiguousCharacters() {
        let code = ConfirmationCode.generate()
        let chars = code.replacingOccurrences(of: "-", with: "")
        
        // Should not contain: I, O, 0, 1, L
        XCTAssertFalse(chars.contains("I"))
        XCTAssertFalse(chars.contains("O"))
        XCTAssertFalse(chars.contains("0"))
        XCTAssertFalse(chars.contains("1"))
        XCTAssertFalse(chars.contains("L"))
    }
    
    // MARK: - Uniqueness Tests
    
    func testGenerateProducesUniqueCodesHighProbability() {
        var codes = Set<String>()
        
        // Generate 100 codes - should be highly unlikely to have duplicates
        for _ in 0..<100 {
            let code = ConfirmationCode.generate()
            codes.insert(code)
        }
        
        // With 32 possible characters and 8 positions, duplicates are extremely rare
        XCTAssertGreaterThan(codes.count, 95) // Allow tiny chance of collision
    }
    
    func testMultipleGenerationsAreDifferent() {
        let code1 = ConfirmationCode.generate()
        let code2 = ConfirmationCode.generate()
        let code3 = ConfirmationCode.generate()
        
        // Very high probability they're all different
        XCTAssertTrue(code1 != code2 || code2 != code3 || code1 != code3)
    }
    
    // MARK: - Consistency Tests
    
    func testGenerateAlwaysReturnsCorrectLength() {
        for _ in 0..<20 {
            let code = ConfirmationCode.generate()
            XCTAssertEqual(code.count, 9)
        }
    }
    
    func testGenerateAlwaysHasOneDash() {
        for _ in 0..<20 {
            let code = ConfirmationCode.generate()
            let dashCount = code.filter { $0 == "-" }.count
            XCTAssertEqual(dashCount, 1)
        }
    }
    
    func testGenerateAlwaysUppercase() {
        let code = ConfirmationCode.generate()
        let nonDashChars = code.filter { $0 != "-" }
        
        XCTAssertEqual(String(nonDashChars), String(nonDashChars).uppercased())
    }
    
    // MARK: - Character Distribution Tests
    
    func testGenerateContainsLetters() {
        let code = ConfirmationCode.generate()
        let chars = code.replacingOccurrences(of: "-", with: "")
        let letters = chars.filter { $0.isLetter }
        
        // Should have at least some letters
        XCTAssertGreaterThan(letters.count, 0)
    }
    
    func testGenerateContainsNumbers() {
        // Run multiple times to increase probability of seeing numbers
        var hasNumbers = false
        for _ in 0..<20 {
            let code = ConfirmationCode.generate()
            let chars = code.replacingOccurrences(of: "-", with: "")
            if chars.contains(where: { $0.isNumber }) {
                hasNumbers = true
                break
            }
        }
        
        XCTAssertTrue(hasNumbers)
    }
    
    // MARK: - Format Validation Tests
    
    func testGenerateDashPosition() {
        let code = ConfirmationCode.generate()
        
        // Dash should be at index 4
        XCTAssertEqual(code[code.index(code.startIndex, offsetBy: 4)], "-")
    }
    
    func testGenerateNoDashesInGroups() {
        let code = ConfirmationCode.generate()
        let components = code.split(separator: "-")
        
        for component in components {
            XCTAssertFalse(component.contains("-"))
        }
    }
}
