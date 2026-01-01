import Foundation
import Network

protocol NetworkMonitorable: AnyObject {
    var isConnected: Bool { get }
    var connectionType: NWInterface.InterfaceType? { get }
    var isExpensive: Bool { get }
    var isConstrained: Bool { get }
    func startMonitoring()
    func stopMonitoring()
}
