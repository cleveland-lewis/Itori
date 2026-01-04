//
//  WatchRootView.swift
//  Itori (watchOS)
//

#if os(watchOS)
import SwiftUI

struct WatchRootView: View {
    @StateObject private var syncManager = WatchSyncManager.shared
    
    var body: some View {
        TabView {
            // Timer Tab
            NavigationStack {
                WatchTimerView()
            }
            .tabItem {
                Label("Timer", systemImage: "timer")
            }
            
            // Tasks Tab
            NavigationStack {
                WatchTasksView()
            }
            .tabItem {
                Label("Tasks", systemImage: "checkmark.circle")
            }
            
            // Settings Tab
            NavigationStack {
                WatchSettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .environmentObject(syncManager)
    }
}

#endif
