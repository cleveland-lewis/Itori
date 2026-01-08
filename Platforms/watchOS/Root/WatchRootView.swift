//
//  WatchRootView.swift
//  Itori (watchOS)
//

#if os(watchOS)
import SwiftUI

struct WatchRootView: View {
    @StateObject private var syncManager = WatchSyncManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    WatchTimerView()
                } label: {
                    Label(NSLocalizedString("Timer", value: "Timer", comment: ""), systemImage: "timer")
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                
                NavigationLink {
                    WatchTasksView()
                } label: {
                    Label(NSLocalizedString("Planner", value: "Planner", comment: ""), systemImage: "calendar")
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                
                NavigationLink {
                    WatchSettingsView()
                } label: {
                    Label(NSLocalizedString("Settings", value: "Settings", comment: ""), systemImage: "gear")
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
            }
            .navigationTitle("Itori")
            .scrollContentBackground(.hidden)
            .background(.ultraThinMaterial)
        }
        .environmentObject(syncManager)
    }
}

#endif
