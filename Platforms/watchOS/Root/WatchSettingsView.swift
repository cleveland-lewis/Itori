//
//  WatchSettingsView.swift
//  Itori (watchOS)
//

#if os(watchOS)
import SwiftUI

struct WatchSettingsView: View {
    @EnvironmentObject var syncManager: WatchSyncManager
    @AppStorage("watchTimerDisplayStyle") private var displayStyle: String = "digital"
    @AppStorage("watchDefaultTimerMode") private var defaultTimerMode: String = "pomodoro"
    
    private var hasActiveSession: Bool {
        syncManager.activeTimer != nil
    }
    
    var body: some View {
        List {
            // Timer Section
            Section("Timer") {
                // Display Style
                Picker("Display", selection: $displayStyle) {
                    Text(NSLocalizedString("Digital", value: "Digital", comment: "")).tag("digital")
                    Text(NSLocalizedString("Analog", value: "Analog", comment: "")).tag("analog")
                }
                
                // Default Mode (disabled if session active)
                VStack(alignment: .leading, spacing: 4) {
                    Picker("Default Mode", selection: $defaultTimerMode) {
                        Text(NSLocalizedString("Pomodoro", value: "Pomodoro", comment: "")).tag("pomodoro")
                        Text(NSLocalizedString("Timer", value: "Timer", comment: "")).tag("timer")
                        Text(NSLocalizedString("Stopwatch", value: "Stopwatch", comment: "")).tag("stopwatch")
                    }
                    .disabled(hasActiveSession)
                    
                    if hasActiveSession {
                        Text(NSLocalizedString("Stop timer to change mode", value: "Stop timer to change mode", comment: ""))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Tasks Section
            Section("Tasks") {
                NavigationLink {
                    TasksSettingsView()
                } label: {
                    Label(NSLocalizedString("Task Options", value: "Task Options", comment: ""), systemImage: "checkmark.circle")
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
            }
            
            // Planner Section
            Section("Planner") {
                NavigationLink {
                    PlannerSettingsView()
                } label: {
                    Label(NSLocalizedString("Planner Options", value: "Planner Options", comment: ""), systemImage: "calendar")
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
            }
            
            // Sync Status
            Section("Sync") {
                HStack {
                    Text(NSLocalizedString("Status", value: "Status", comment: ""))
                    Spacer()
                    if syncManager.isConnected {
                        Label(NSLocalizedString("Connected", value: "Connected", comment: ""), systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Label(NSLocalizedString("Disconnected", value: "Disconnected", comment: ""), systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let lastSync = syncManager.lastSyncDate {
                    HStack {
                        Text(NSLocalizedString("Last Sync", value: "Last Sync", comment: ""))
                        Spacer()
                        Text(lastSync, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // App Info
            Section {
                HStack {
                    Text(NSLocalizedString("Version", value: "Version", comment: ""))
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}

private struct TasksSettingsView: View {
    @AppStorage("watchShowCompletedTasks") private var showCompleted: Bool = true
    @AppStorage("watchTasksLimit") private var tasksLimit: Int = 20
    
    var body: some View {
        List {
            Section("Display") {
                Toggle("Show Completed", isOn: $showCompleted)
                
                Stepper("Show \(tasksLimit) tasks", value: $tasksLimit, in: 5...50, step: 5)
            }
            
            Section {
                Text(NSLocalizedString("Control which tasks appear on your watch.", value: "Control which tasks appear on your watch.", comment: ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}

private struct PlannerSettingsView: View {
    @AppStorage("watchShowTodayOnly") private var showTodayOnly: Bool = true
    @AppStorage("watchShowUpcoming") private var showUpcoming: Bool = true
    
    var body: some View {
        List {
            Section("Display") {
                Toggle("Today Only", isOn: $showTodayOnly)
                Toggle("Show Upcoming", isOn: $showUpcoming)
            }
            
            Section {
                Text(NSLocalizedString("Control your planner view on watch.", value: "Control your planner view on watch.", comment: ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Planner")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}

#endif
