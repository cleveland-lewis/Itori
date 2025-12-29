//
// AIKillSwitch.swift
// Hard gate at engine boundary - single point of control
//

import Foundation

/// Global kill switch for all AI operations
public actor AIKillSwitch {
    private var enabled: Bool
    private var disabledReason: String?
    
    public init(enabled: Bool = true) {
        self.enabled = enabled
    }
    
    /// Check if AI is enabled
    public func isEnabled() -> Bool {
        enabled
    }
    
    /// Disable all AI operations
    public func disable(reason: String) {
        enabled = false
        disabledReason = reason
    }
    
    /// Enable AI operations
    public func enable() {
        enabled = true
        disabledReason = nil
    }
    
    /// Get status for diagnostics
    public func status() -> (enabled: Bool, reason: String?) {
        (enabled, disabledReason)
    }
}

/// Per-port enable/disable control
public actor AIPortController {
    private var disabledPorts: Set<AIPortID>
    private var disableReasons: [AIPortID: String]
    
    public init() {
        self.disabledPorts = []
        self.disableReasons = [:]
    }
    
    /// Check if a port is enabled
    public func isEnabled(_ portID: AIPortID) -> Bool {
        !disabledPorts.contains(portID)
    }
    
    /// Disable a specific port
    public func disable(_ portID: AIPortID, reason: String) {
        disabledPorts.insert(portID)
        disableReasons[portID] = reason
    }
    
    /// Enable a specific port
    public func enable(_ portID: AIPortID) {
        disabledPorts.remove(portID)
        disableReasons.removeValue(forKey: portID)
    }
    
    /// Get all disabled ports
    public func getDisabled() -> [(port: AIPortID, reason: String)] {
        disabledPorts.map { port in
            (port, disableReasons[port] ?? "Unknown")
        }
    }
}
