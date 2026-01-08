import SwiftUI
import Combine
#if os(iOS)

struct IOSPlannerSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @State private var showingNotifications = false
    
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

            IOSIntelligentSchedulingSettingsContent(
                coordinator: IntelligentSchedulingCoordinator.shared,
                gradeMonitor: GradeMonitoringService.shared,
                autoReschedule: EnhancedAutoRescheduleService.shared,
                settings: settings,
                showingNotifications: $showingNotifications
            )
        }
        .listStyle(.insetGrouped)
        .navigationTitle(NSLocalizedString("settings.category.planner", comment: "Planner"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNotifications) {
            AllNotificationsView()
        }
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
