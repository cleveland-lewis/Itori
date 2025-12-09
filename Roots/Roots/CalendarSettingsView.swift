import SwiftUI
import EventKit

struct CalendarSettingsView: View {
    @EnvironmentObject var calendarManager: CalendarManager

    var body: some View {
        Form {
            Section("Calendar") {
                Toggle("Enable Calendar Sync", isOn: Binding(
                    get: { calendarManager.eventAuthorizationStatus == .authorized || calendarManager.eventAuthorizationStatus == .fullAccess },
                    set: { newValue in
                        if newValue { _Concurrency.Task { await calendarManager.requestCalendarAccess() } }
                    }
                ))
                .toggleStyle(.switch)
                .onChange(of: calendarManager.eventAuthorizationStatus) { _, _ in /* UI updates via calendarManager published */ }

                HStack {
                    Text("Status:")
                        .foregroundStyle(.secondary)
                    if calendarManager.eventAuthorizationStatus == .authorized || calendarManager.eventAuthorizationStatus == .fullAccess {
                        Text("Connected").foregroundStyle(.green)
                    } else if calendarManager.isCalendarAccessDenied {
                        Text("Access Denied").foregroundStyle(.red)
                        Button("Open Settings") { calendarManager.openSystemPrivacySettings() }
                            .buttonStyle(.link)
                    } else {
                        Text("Not Connected").foregroundStyle(.secondary)
                    }
                }
                .font(DesignSystem.Typography.caption)
            }
        }
        .formStyle(.grouped)
    }
}