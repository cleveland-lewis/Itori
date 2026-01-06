import SwiftUI
import Combine
#if os(iOS)

struct IOSPlannerSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    
    var body: some View {
        List {
            Section {
                Text(NSLocalizedString("settings.planner.body", value: "Planner configuration settings", comment: "Planner settings body"))
                    .foregroundColor(.secondary)
            } header: {
                Text(NSLocalizedString("settings.planner.header", value: "Planning", comment: "Planner header"))
            } footer: {
                Text(NSLocalizedString("settings.planner.footer", value: "Configure how assignments are automatically scheduled", comment: "Planner footer"))
            }
            
            // Auto-Reschedule Section
            Section {
                Toggle(NSLocalizedString("settings.planner.reschedule.enable", value: "Enable Auto-Reschedule", comment: "Enable auto-reschedule"), isOn: Binding(
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
                            Text(NSLocalizedString("settings.planner.reschedule.interval", value: "Check Interval", comment: "Auto-reschedule check interval label"))
                            Spacer()
                            Text(String(format: NSLocalizedString("settings.planner.reschedule.interval.value", value: "%d min", comment: "Auto-reschedule check interval value"), settings.autoRescheduleCheckInterval))
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
                    
                    Toggle(NSLocalizedString("settings.planner.reschedule.push_lower", value: "Allow Pushing Lower Priority Tasks", comment: "Allow pushing lower priority tasks"), isOn: Binding(
                        get: { settings.autoReschedulePushLowerPriority },
                        set: { settings.autoReschedulePushLowerPriority = $0; settings.save() }
                    ))
                    
                    if settings.autoReschedulePushLowerPriority {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(NSLocalizedString("settings.planner.reschedule.max_push", value: "Max Tasks to Push", comment: "Max tasks to push label"))
                                Spacer()
                                Text(verbatim: "\(settings.autoRescheduleMaxPushCount)")
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
                            .navigationTitle(NSLocalizedString("settings.planner.reschedule.history.title", value: "Reschedule History", comment: "Reschedule history title"))
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack {
                            Text(NSLocalizedString("settings.planner.reschedule.history", value: "View History", comment: "View reschedule history"))
                            Spacer()
                            Text(verbatim: "\(AutoRescheduleEngine.shared.rescheduleHistory.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text(NSLocalizedString("settings.planner.reschedule.header", value: "Auto-Reschedule", comment: "Auto-reschedule header"))
            } footer: {
                Text(settings.enableAutoReschedule
                     ? NSLocalizedString("settings.planner.reschedule.footer.enabled", value: "Automatically reschedule missed tasks to available time slots. Tasks you've manually edited or locked will never be moved.", comment: "Auto-reschedule footer enabled")
                     : NSLocalizedString("settings.planner.reschedule.footer.disabled", value: "When enabled, missed tasks are automatically rescheduled to keep your schedule up-to-date.", comment: "Auto-reschedule footer disabled"))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(NSLocalizedString("settings.category.planner", comment: "Planner"))
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
