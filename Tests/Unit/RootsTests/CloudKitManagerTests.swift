//
//  CloudKitManagerTests.swift
//  RootsTests
//
//  Phase 6.1: iCloud Sync Testing
//

import XCTest
@testable import Roots

final class CloudKitManagerTests: XCTestCase {
    var mockCloudKit: MockCloudKitManager!
    
    override func setUp() {
        super.setUp()
        mockCloudKit = MockCloudKitManager()
    }
    
    override func tearDown() {
        mockCloudKit = nil
        super.tearDown()
    }
    
    // MARK: - Successful Sync Tests
    
    func testSyncToCloudSuccess() async throws {
        let testData = "Test Data".data(using: .utf8)!
        
        try await mockCloudKit.syncToCloud(key: "test_key", data: testData)
        
        XCTAssertEqual(mockCloudKit.syncCallCount, 1)
        XCTAssertEqual(mockCloudKit.syncedData["test_key"], testData)
    }
    
    func testFetchFromCloudSuccess() async throws {
        let testData = "Test Data".data(using: .utf8)!
        mockCloudKit.syncedData["test_key"] = testData
        
        let fetched = try await mockCloudKit.fetchFromCloud(key: "test_key")
        
        XCTAssertEqual(mockCloudKit.fetchCallCount, 1)
        XCTAssertEqual(fetched, testData)
    }
    
    func testMultipleSyncsToSameKey() async throws {
        let data1 = "Data 1".data(using: .utf8)!
        let data2 = "Data 2".data(using: .utf8)!
        
        try await mockCloudKit.syncToCloud(key: "key", data: data1)
        try await mockCloudKit.syncToCloud(key: "key", data: data2)
        
        XCTAssertEqual(mockCloudKit.syncCallCount, 2)
        XCTAssertEqual(mockCloudKit.syncedData["key"], data2)
    }
    
    // MARK: - Network Failure Tests
    
    func testSyncFailsWhenOffline() async {
        mockCloudKit.isConnected = false
        let testData = "Test".data(using: .utf8)!
        
        do {
            try await mockCloudKit.syncToCloud(key: "test", data: testData)
            XCTFail("Should have thrown network error")
        } catch MockCloudKitError.networkUnavailable {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testFetchFailsWhenOffline() async {
        mockCloudKit.isConnected = false
        
        do {
            _ = try await mockCloudKit.fetchFromCloud(key: "test")
            XCTFail("Should have thrown network error")
        } catch MockCloudKitError.networkUnavailable {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    // MARK: - Conflict Resolution Tests
    
    func testConflictDetectionWithoutResolver() async {
        let data1 = "Original".data(using: .utf8)!
        let data2 = "Modified".data(using: .utf8)!
        
        try? await mockCloudKit.syncToCloud(key: "conflict_key", data: data1)
        
        do {
            try await mockCloudKit.syncToCloud(key: "conflict_key", data: data2)
            XCTFail("Should have detected conflict")
        } catch MockCloudKitError.conflictDetected {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testConflictResolutionWithResolver() async throws {
        let data1 = "Original".data(using: .utf8)!
        let data2 = "Modified".data(using: .utf8)!
        
        // Set resolver to always prefer newer data
        mockCloudKit.conflictResolver = { _, new in new }
        
        try await mockCloudKit.syncToCloud(key: "conflict_key", data: data1)
        try await mockCloudKit.syncToCloud(key: "conflict_key", data: data2)
        
        XCTAssertEqual(mockCloudKit.syncedData["conflict_key"], data2)
    }
    
    // MARK: - Quota Tests
    
    func testQuotaExceeded() async {
        mockCloudKit.quotaRemaining = 100
        let largeData = Data(repeating: 0, count: 200)
        
        do {
            try await mockCloudKit.syncToCloud(key: "large", data: largeData)
            XCTFail("Should have exceeded quota")
        } catch MockCloudKitError.quotaExceeded {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testQuotaDecreasesAfterSync() async throws {
        let initialQuota = mockCloudKit.quotaRemaining
        let testData = Data(repeating: 0, count: 1000)
        
        try await mockCloudKit.syncToCloud(key: "test", data: testData)
        
        XCTAssertEqual(mockCloudKit.quotaRemaining, initialQuota - 1000)
    }
    
    // MARK: - Background Sync Tests
    
    func testMultipleKeysSync() async throws {
        let keys = ["key1", "key2", "key3"]
        let data = "Data".data(using: .utf8)!
        
        for key in keys {
            try await mockCloudKit.syncToCloud(key: key, data: data)
        }
        
        XCTAssertEqual(mockCloudKit.syncCallCount, 3)
        XCTAssertEqual(mockCloudKit.syncedData.count, 3)
    }
    
    func testClearCache() {
        mockCloudKit.syncedData["test"] = Data()
        mockCloudKit.syncCallCount = 5
        
        mockCloudKit.clearCache()
        
        XCTAssertTrue(mockCloudKit.syncedData.isEmpty)
        XCTAssertEqual(mockCloudKit.syncCallCount, 0)
        XCTAssertEqual(mockCloudKit.quotaRemaining, 1_000_000_000)
    }
}
