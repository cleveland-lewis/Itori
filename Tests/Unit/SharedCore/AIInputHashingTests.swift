import XCTest
@testable import SharedCore

final class AIInputHashingTests: XCTestCase {
    func testInputHashStableAcrossKeyOrderAndExcludedKeys() {
        let first: [String: Any] = [
            "title": "Essay",
            "requestID": "123",
            "timestamp": "2025-01-01T00:00:00Z",
            "details": [
                "category": "writing",
                "difficulty": 3
            ]
        ]
        let second: [String: Any] = [
            "details": [
                "difficulty": 3,
                "category": "writing"
            ],
            "timestamp": "2025-02-01T00:00:00Z",
            "requestID": "999",
            "title": "Essay"
        ]

        let data1 = try! JSONSerialization.data(withJSONObject: first, options: [])
        let data2 = try! JSONSerialization.data(withJSONObject: second, options: [])

        let hash1 = AIInputHasher.hash(inputJSON: data1)
        let hash2 = AIInputHasher.hash(inputJSON: data2)

        XCTAssertEqual(hash1, hash2, "Canonicalized input hashes should match for logically identical data")
    }

    func testInputHashNormalizesUnorderedArrays() {
        let first: [String: Any] = [
            "tags": ["b", "a", "c"],
            "title": "Reading"
        ]
        let second: [String: Any] = [
            "title": "Reading",
            "tags": ["c", "b", "a"]
        ]

        let data1 = try! JSONSerialization.data(withJSONObject: first, options: [])
        let data2 = try! JSONSerialization.data(withJSONObject: second, options: [])

        let hash1 = AIInputHasher.hash(inputJSON: data1, unorderedArrayKeys: ["tags"])
        let hash2 = AIInputHasher.hash(inputJSON: data2, unorderedArrayKeys: ["tags"])

        XCTAssertEqual(hash1, hash2, "Unordered arrays should hash identically when normalized")
    }
}
