//
//  MockCloudKitManager.swift
//  ItoriTests
//
//  Created for Phase 6.1: iCloud Sync Testing
//

import Foundation
@testable import Itori

enum MockCloudKitError: Error {
    case syncFailed
    case networkUnavailable
    case quotaExceeded
    case conflictDetected
}

class MockCloudKitManager {
    var shouldFail = false
    var failureError: MockCloudKitError = .syncFailed
    var syncedData: [String: Data] = [:]
    var syncCallCount = 0
    var fetchCallCount = 0
    var conflictResolver: ((Data, Data) -> Data)?
    
    var isConnected = true
    var quotaRemaining: Int64 = 1_000_000_000 // 1GB
    
    func syncToCloud(key: String, data: Data) async throws {
        syncCallCount += 1
        
        if !isConnected {
            throw MockCloudKitError.networkUnavailable
        }
        
        if Int64(data.count) > quotaRemaining {
            throw MockCloudKitError.quotaExceeded
        }
        
        if shouldFail {
            throw failureError
        }
        
        // Simulate conflict
        if let existingData = syncedData[key], existingData != data {
            if let resolver = conflictResolver {
                syncedData[key] = resolver(existingData, data)
            } else {
                throw MockCloudKitError.conflictDetected
            }
        } else {
            syncedData[key] = data
            quotaRemaining -= Int64(data.count)
        }
    }
    
    func fetchFromCloud(key: String) async throws -> Data? {
        fetchCallCount += 1
        
        if !isConnected {
            throw MockCloudKitError.networkUnavailable
        }
        
        if shouldFail {
            throw failureError
        }
        
        return syncedData[key]
    }
    
    func clearCache() {
        syncedData.removeAll()
        syncCallCount = 0
        fetchCallCount = 0
        quotaRemaining = 1_000_000_000
    }
}
