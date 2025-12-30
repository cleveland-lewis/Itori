//
//  WatchConnectivityManager.swift
//  Roots (Shared)
//
//  Created by AI Agent on 2024-12-30
//  Purpose: Sync data between iPhone and Apple Watch
//

import Foundation
import Combine
#if os(iOS) || os(watchOS)
import WatchConnectivity
#endif

#if os(iOS) || os(watchOS)

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isReachable: Bool = false
    @Published var isPaired: Bool = false
    @Published var isWatchAppInstalled: Bool = false
    @Published var lastMessage: [String: Any]?
    
    private var session: WCSession?
    
    private override init() {
        super.init()
        
        #if DEBUG
        print("🔗 WatchConnectivityManager: Initializing")
        #endif
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            
            #if DEBUG
            print("🔗 WatchConnectivityManager: Session activated")
            #endif
        } else {
            #if DEBUG
            print("⚠️  WatchConnectivityManager: WCSession not supported on this device")
            #endif
        }
    }
    
    // MARK: - Send Message
    
    func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        guard let session = session, session.isReachable else {
            #if DEBUG
            print("❌ WatchConnectivityManager: Cannot send message - session not reachable")
            #endif
            errorHandler?(NSError(domain: "WatchConnectivity", code: -1, userInfo: [NSLocalizedDescriptionKey: "Watch not reachable"]))
            return
        }
        
        session.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
        
        #if DEBUG
        print("📤 WatchConnectivityManager: Sent message: \(message.keys.joined(separator: ", "))")
        #endif
    }
    
    // MARK: - Update Application Context
    
    func updateApplicationContext(_ context: [String: Any]) throws {
        guard let session = session else {
            throw NSError(domain: "WatchConnectivity", code: -1, userInfo: [NSLocalizedDescriptionKey: "Session not available"])
        }
        
        try session.updateApplicationContext(context)
        
        #if DEBUG
        print("📤 WatchConnectivityManager: Updated application context: \(context.keys.joined(separator: ", "))")
        #endif
    }
    
    // MARK: - Transfer User Info
    
    func transferUserInfo(_ userInfo: [String: Any]) -> WCSessionUserInfoTransfer {
        guard let session = session else {
            fatalError("Session not available")
        }
        
        let transfer = session.transferUserInfo(userInfo)
        
        #if DEBUG
        print("📤 WatchConnectivityManager: Transferring user info: \(userInfo.keys.joined(separator: ", "))")
        #endif
        
        return transfer
    }
    
    // MARK: - Debug Status
    
    #if DEBUG
    func printStatus() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔗 WatchConnectivityManager Status")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        if let session = session {
            #if os(iOS)
            print("  Platform: iOS")
            print("  Paired: \(session.isPaired)")
            print("  Watch App Installed: \(session.isWatchAppInstalled)")
            #else
            print("  Platform: watchOS")
            #endif
            
            print("  Reachable: \(session.isReachable)")
            print("  Activation State: \(session.activationState.description)")
            
            #if os(iOS)
            if session.isPaired {
                print("  Paired Watch: \(session.isWatchAppInstalled ? "App Installed ✅" : "App Not Installed ❌")")
            }
            #endif
        } else {
            print("  Session: Not available")
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    #endif
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                #if DEBUG
                print("❌ WatchConnectivityManager: Activation failed: \(error.localizedDescription)")
                #endif
                return
            }
            
            #if os(iOS)
            isPaired = session.isPaired
            isWatchAppInstalled = session.isWatchAppInstalled
            #endif
            
            isReachable = session.isReachable
            
            #if DEBUG
            print("✅ WatchConnectivityManager: Activation complete - State: \(activationState.description)")
            printStatus()
            #endif
        }
    }
    
    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        #if DEBUG
        print("⚠️  WatchConnectivityManager: Session became inactive")
        #endif
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        #if DEBUG
        print("⚠️  WatchConnectivityManager: Session deactivated - reactivating...")
        #endif
        session.activate()
    }
    
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            isPaired = session.isPaired
            isWatchAppInstalled = session.isWatchAppInstalled
            isReachable = session.isReachable
            
            #if DEBUG
            print("🔄 WatchConnectivityManager: Watch state changed")
            printStatus()
            #endif
        }
    }
    #endif
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            
            #if DEBUG
            print("🔄 WatchConnectivityManager: Reachability changed to \(session.isReachable ? "reachable ✅" : "not reachable ❌")")
            #endif
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            lastMessage = message
            
            #if DEBUG
            print("📥 WatchConnectivityManager: Received message: \(message)")
            #endif
            
            // Handle message here
            handleReceivedMessage(message)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            lastMessage = message
            
            #if DEBUG
            print("📥 WatchConnectivityManager: Received message with reply handler: \(message)")
            #endif
            
            // Handle message and send reply
            let reply = handleReceivedMessageWithReply(message)
            replyHandler(reply)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            #if DEBUG
            print("📥 WatchConnectivityManager: Received application context: \(applicationContext)")
            #endif
            
            // Handle application context here
            handleReceivedApplicationContext(applicationContext)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            #if DEBUG
            print("📥 WatchConnectivityManager: Received user info: \(userInfo)")
            #endif
            
            // Handle user info here
            handleReceivedUserInfo(userInfo)
        }
    }
    
    // MARK: - Message Handlers
    
    @MainActor
    private func handleReceivedMessage(_ message: [String: Any]) {
        // TODO: Implement message handling logic
        // Example: Sync assignments, courses, timer state, etc.
    }
    
    @MainActor
    private func handleReceivedMessageWithReply(_ message: [String: Any]) -> [String: Any] {
        // TODO: Implement message handling with reply
        // Example: Request for current assignments, return list
        return ["status": "received"]
    }
    
    @MainActor
    private func handleReceivedApplicationContext(_ context: [String: Any]) {
        // TODO: Implement context handling
        // Example: Update local data with context from other device
    }
    
    @MainActor
    private func handleReceivedUserInfo(_ userInfo: [String: Any]) {
        // TODO: Implement user info handling
        // Example: Sync background data updates
    }
}

// MARK: - WCSessionActivationState Extension

extension WCSessionActivationState {
    var description: String {
        switch self {
        case .notActivated: return "Not Activated"
        case .inactive: return "Inactive"
        case .activated: return "Activated"
        @unknown default: return "Unknown"
        }
    }
}

#endif // os(iOS) || os(watchOS)
