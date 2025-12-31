//
//  WatchSettingsView.swift
//  Roots (watchOS)
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
                    Text("Digital").tag("digital")
                    Text("Analog").tag("analog")
                }
                
                // Default Mode (disabled if session active)
                VStack(alignment: .leading, spacing: 4) {
                    Picker("Default Mode", selection: $defaultTimerMode) {
                        Text("Pomodoro").tag("pomodoro")
                        Text("Timer").tag("timer")
                        Text("Stopwatch").tag("stopwatch")
                    }
                    .disabled(hasActiveSession)
                    
                    if hasActiveSession {
                        Text("Stop timer to change mode")
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
                    Label("Task Options", systemImage: "checkmark.circle")
                }
            }
            
            // Planner Section
            Section("Planner") {
                NavigationLink {
                    PlannerSettingsView()
                } label: {
                    Label("Planner Options", systemImage: "calendar")
                }
            }
            
            // Sync Status
            Section("Sync") {
                HStack {
                    Text("Status")
                    Spacer()
                    if syncManager.isConnected {
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Label("Disconnected", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let lastSync = syncManager.lastSyncDate {
                    HStack {
                        Text("Last Sync")
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
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
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
                Text("Control which tasks appear on your watch.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.inline)
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
                Text("Control your planner view on watch.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Planner")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#endif
