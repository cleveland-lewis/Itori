//
//  ItoriWatchApp.swift
//  Itori (watchOS)
//

#if os(watchOS)
import SwiftUI

@main
struct ItoriWatchApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var syncManager = WatchSyncManager.shared
    
    var body: some Scene {
        WindowGroup {
            WatchRootView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // App became active - request fresh sync
            print("📱 WatchApp: Active - requesting sync")
            Task { @MainActor in
                syncManager.requestFullSync()
            }
        case .background:
            // App went to background
            print("📱 WatchApp: Background")
        case .inactive:
            // App becoming inactive
            print("📱 WatchApp: Inactive")
        @unknown default:
            break
        }
    }
}
#endif
