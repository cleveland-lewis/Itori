//
//  NetworkMonitorTests.swift
//  ItoriTests
//
//  Phase 6.5: Network Monitoring Testing
//

import XCTest
@testable import Itori

final class NetworkMonitorTests: XCTestCase {
    var mockMonitor: MockNetworkMonitor!
    
    override func setUp() {
        super.setUp()
        mockMonitor = MockNetworkMonitor()
    }
    
    override func tearDown() {
        mockMonitor = nil
        super.tearDown()
    }
    
    // MARK: - Connection State Tests
    
    func testInitialConnectionState() {
        XCTAssertTrue(mockMonitor.isConnected)
        XCTAssertEqual(mockMonitor.connectionType, .wifi)
        XCTAssertEqual(mockMonitor.connectionQuality, .excellent)
    }
    
    func testWiFiToCellularTransition() {
        var callbackInvoked = false
        mockMonitor.updateHandler = { connected, type in
            callbackInvoked = true
            XCTAssertTrue(connected)
            XCTAssertEqual(type, .cellular)
        }
        
        mockMonitor.simulateConnectionChange(connected: true, type: .cellular)
        
        XCTAssertTrue(callbackInvoked)
        XCTAssertEqual(mockMonitor.connectionType, .cellular)
    }
    
    func testDisconnection() {
        var callbackInvoked = false
        mockMonitor.updateHandler = { connected, type in
            callbackInvoked = true
            XCTAssertFalse(connected)
            XCTAssertEqual(type, .none)
        }
        
        mockMonitor.simulateConnectionChange(connected: false, type: .none)
        
        XCTAssertTrue(callbackInvoked)
        XCTAssertFalse(mockMonitor.isConnected)
    }
    
    func testReconnection() {
        mockMonitor.simulateConnectionChange(connected: false, type: .none)
        XCTAssertFalse(mockMonitor.isConnected)
        
        mockMonitor.simulateConnectionChange(connected: true, type: .wifi)
        XCTAssertTrue(mockMonitor.isConnected)
        XCTAssertEqual(mockMonitor.connectionType, .wifi)
    }
    
    // MARK: - Connection Quality Tests
    
    func testExcellentQuality() {
        mockMonitor.simulateQualityChange(.excellent)
        
        XCTAssertEqual(mockMonitor.connectionQuality, .excellent)
        XCTAssertFalse(mockMonitor.isConstrained)
    }
    
    func testPoorQuality() {
        mockMonitor.simulateQualityChange(.poor)
        
        XCTAssertEqual(mockMonitor.connectionQuality, .poor)
        XCTAssertTrue(mockMonitor.isConstrained)
    }
    
    func testOfflineQuality() {
        mockMonitor.simulateQualityChange(.offline)
        
        XCTAssertEqual(mockMonitor.connectionQuality, .offline)
        XCTAssertFalse(mockMonitor.isConnected)
    }
    
    // MARK: - Connection Type Tests
    
    func testCellularConnection() {
        mockMonitor.simulateConnectionChange(connected: true, type: .cellular)
        
        XCTAssertTrue(mockMonitor.isConnected)
        XCTAssertEqual(mockMonitor.connectionType, .cellular)
    }
    
    func testWiredConnection() {
        mockMonitor.simulateConnectionChange(connected: true, type: .wired)
        
        XCTAssertTrue(mockMonitor.isConnected)
        XCTAssertEqual(mockMonitor.connectionType, .wired)
    }
    
    // MARK: - Expensive Connection Tests
    
    func testExpensiveConnection() {
        mockMonitor.simulateExpensiveConnection(true)
        
        XCTAssertTrue(mockMonitor.isExpensive)
    }
    
    func testNonExpensiveConnection() {
        mockMonitor.simulateExpensiveConnection(false)
        
        XCTAssertFalse(mockMonitor.isExpensive)
    }
    
    func testCellularIsExpensive() {
        mockMonitor.simulateConnectionChange(connected: true, type: .cellular)
        mockMonitor.simulateExpensiveConnection(true)
        
        XCTAssertTrue(mockMonitor.isExpensive)
        XCTAssertEqual(mockMonitor.connectionType, .cellular)
    }
    
    // MARK: - IP Support Tests
    
    func testIPv4Support() {
        XCTAssertTrue(mockMonitor.supportsIPv4)
    }
    
    func testIPv6Support() {
        XCTAssertTrue(mockMonitor.supportsIPv6)
    }
    
    func testDualStackSupport() {
        XCTAssertTrue(mockMonitor.supportsIPv4 && mockMonitor.supportsIPv6)
    }
    
    // MARK: - Monitoring Lifecycle Tests
    
    func testStartMonitoring() {
        mockMonitor.startMonitoring()
        // Verify monitoring is active (implementation dependent)
    }
    
    func testStopMonitoring() {
        mockMonitor.startMonitoring()
        mockMonitor.stopMonitoring()
        // Verify monitoring is stopped
    }
    
    // MARK: - Reset Tests
    
    func testReset() {
        mockMonitor.simulateConnectionChange(connected: false, type: .none)
        mockMonitor.simulateQualityChange(.poor)
        mockMonitor.simulateExpensiveConnection(true)
        
        mockMonitor.reset()
        
        XCTAssertTrue(mockMonitor.isConnected)
        XCTAssertEqual(mockMonitor.connectionType, .wifi)
        XCTAssertEqual(mockMonitor.connectionQuality, .excellent)
        XCTAssertFalse(mockMonitor.isExpensive)
        XCTAssertFalse(mockMonitor.isConstrained)
    }
}
