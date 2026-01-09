//
//  MockNetworkMonitor.swift
//  ItoriTests
//
//  Created for Phase 6.5: Network Monitoring Testing
//

import Foundation
import Network
@testable import Itori

enum ConnectionType {
    case wifi
    case cellular
    case wired
    case other
    case none
}

enum ConnectionQuality {
    case excellent
    case good
    case poor
    case offline
}

class MockNetworkMonitor {
    var isConnected = true
    var connectionType: ConnectionType = .wifi
    var connectionQuality: ConnectionQuality = .excellent
    var isExpensive = false
    var isConstrained = false
    var supportsIPv4 = true
    var supportsIPv6 = true
    var updateHandler: ((Bool, ConnectionType) -> Void)?

    func startMonitoring() {
        // Simulate monitoring
    }

    func stopMonitoring() {
        // Stop monitoring
    }

    func simulateConnectionChange(connected: Bool, type: ConnectionType) {
        isConnected = connected
        connectionType = type
        updateHandler?(connected, type)
    }

    func simulateQualityChange(_ quality: ConnectionQuality) {
        connectionQuality = quality

        switch quality {
        case .excellent:
            isConstrained = false
        case .good:
            isConstrained = false
        case .poor:
            isConstrained = true
        case .offline:
            isConnected = false
        }
    }

    func simulateExpensiveConnection(_ expensive: Bool) {
        isExpensive = expensive
    }

    func reset() {
        isConnected = true
        connectionType = .wifi
        connectionQuality = .excellent
        isExpensive = false
        isConstrained = false
        supportsIPv4 = true
        supportsIPv6 = true
    }
}
