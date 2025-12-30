import SwiftUI
import Combine
#if os(iOS)

struct IOSPlannerSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    
    var body: some View {
        List {
            Section {
                Text("Planner configuration settings")
                    .foregroundColor(.secondary)
            } header: {
                Text("Planning")
            } footer: {
                Text("Configure how assignments are automatically scheduled")
            }
            
            // Auto-Reschedule Section
            Section {
                Toggle("Enable Auto-Reschedule", isOn: Binding(
                    get: { settings.enableAutoReschedule },
                    set: { newValue in
                        settings.enableAutoReschedule = newValue
                        settings.save()
                        // Stop/start monitoring immediately
                        if newValue {
                            MissedEventDetectionService.shared.startMonitoring()
                        } else {
                            MissedEventDetectionService.shared.stopMonitoring()
                        }
                    }
                ))
                
                if settings.enableAutoReschedule {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Check Interval")
                            Spacer()
                            Text("\(settings.autoRescheduleCheckInterval) min")
                                .foregroundColor(.secondary)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(settings.autoRescheduleCheckInterval) },
                                set: { settings.autoRescheduleCheckInterval = Int($0); settings.save() }
                            ),
                            in: 1...60,
                            step: 1
                        )
                        .onChange(of: settings.autoRescheduleCheckInterval) { _, _ in
                            // Restart monitoring with new interval
                            if settings.enableAutoReschedule {
                                MissedEventDetectionService.shared.stopMonitoring()
                                MissedEventDetectionService.shared.startMonitoring()
                            }
                        }
                    }
                    
                    Toggle("Allow Pushing Lower Priority Tasks", isOn: Binding(
                        get: { settings.autoReschedulePushLowerPriority },
                        set: { settings.autoReschedulePushLowerPriority = $0; settings.save() }
                    ))
                    
                    if settings.autoReschedulePushLowerPriority {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Max Tasks to Push")
                                Spacer()
                                Text("\(settings.autoRescheduleMaxPushCount)")
                                    .foregroundColor(.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: { Double(settings.autoRescheduleMaxPushCount) },
                                    set: { settings.autoRescheduleMaxPushCount = Int($0); settings.save() }
                                ),
                                in: 0...5,
                                step: 1
                            )
                        }
                    }
                    
                    NavigationLink {
                        AutoRescheduleHistoryView()
                            .navigationTitle("Reschedule History")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack {
                            Text("View History")
                            Spacer()
                            Text("\(AutoRescheduleEngine.shared.rescheduleHistory.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Auto-Reschedule")
            } footer: {
                Text(settings.enableAutoReschedule 
                     ? "Automatically reschedule missed tasks to available time slots. Tasks you've manually edited or locked will never be moved."
                     : "When enabled, missed tasks are automatically rescheduled to keep your schedule up-to-date.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Planner")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        IOSPlannerSettingsView()
            .environmentObject(AppSettingsModel.shared)
    }
}
#endif
#endif
