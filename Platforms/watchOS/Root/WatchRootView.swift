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
                Label(NSLocalizedString("Timer", value: "Timer", comment: ""), systemImage: "timer")
            }
            
            // Tasks Tab
            NavigationStack {
                WatchTasksView()
            }
            .tabItem {
                Label(NSLocalizedString("Tasks", value: "Tasks", comment: ""), systemImage: "checkmark.circle")
            }
            
            // Settings Tab
            NavigationStack {
                WatchSettingsView()
            }
            .tabItem {
                Label(NSLocalizedString("Settings", value: "Settings", comment: ""), systemImage: "gear")
            }
        }
        .environmentObject(syncManager)
    }
}

#endif
