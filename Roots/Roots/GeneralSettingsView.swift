import SwiftUI
import EventKit

struct GeneralSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var timerManager: TimerManager
    // replaced PermissionsManager with CalendarManager usage

    @State private var userName: String = ""
    @State private var showingRevokeAlert = false

    enum StartOfWeek: String, CaseIterable, Identifiable {
        case sunday = "Sunday"
        case monday = "Monday"

        var id: String { rawValue }
    }

    enum DefaultView: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case calendar = "Calendar"
        case planner = "Planner"
        case courses = "Courses"

        var id: String { rawValue }
    }

    @State private var startOfWeek: StartOfWeek = .sunday
    @State private var defaultView: DefaultView = .dashboard

    private var calendarToggleBinding: Binding<Bool> {
        Binding(get: {
            calendarManager.eventAuthorizationStatus == .authorized || calendarManager.eventAuthorizationStatus == .fullAccess
        }, set: { newValue in
            if newValue {
                _Concurrency.Task { await calendarManager.requestCalendarAccess() }
            } else {
                showingRevokeAlert = true
            }
        })
    }

    private var remindersToggleBinding: Binding<Bool> {
        Binding(get: {
            calendarManager.reminderAuthorizationStatus == .authorized || calendarManager.reminderAuthorizationStatus == .fullAccess
        }, set: { newValue in
            if newValue {
                _Concurrency.Task { await calendarManager.requestRemindersAccess() }
            } else {
                showingRevokeAlert = true
            }
        })
    }

    var body: some View {
        List {
            Section("Personal") {
                TextField("Name", text: $userName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: userName) { _, newValue in
                        settings.userName = newValue
                        settings.save()
                    }
            }

            Section("Preferences") {
                Picker("Start of Week", selection: $startOfWeek) {
                    ForEach(StartOfWeek.allCases) { day in
                        Text(day.rawValue).tag(day)
                    }
                }
                .onChange(of: startOfWeek) { _, newValue in
                    settings.startOfWeek = newValue.rawValue
                    settings.save()
                }

                Picker("Default View", selection: $defaultView) {
                    ForEach(DefaultView.allCases) { view in
                        Text(view.rawValue).tag(view)
                    }
                }
                .onChange(of: defaultView) { _, newValue in
                    settings.defaultView = newValue.rawValue
                    settings.save()
                }
            }

            Section("Display") {
                Toggle("24-Hour Time", isOn: $settings.use24HourTime)
                    .onChange(of: settings.use24HourTime) { _, _ in settings.save() }

                Toggle("Energy Panel", isOn: $settings.showEnergyPanel)
                    .onChange(of: settings.showEnergyPanel) { _, _ in settings.save() }
            }

            // MARK: - Sync & Integrations
            Section(header: Text("Sync & Integrations").accessibilityIdentifier("Settings.SyncIntegrations")) {
                HStack {
                    Text("Enable Apple Sync")
                    Spacer()
                    Toggle("", isOn: Binding(get: { calendarManager.isAuthorized }, set: { val in
                        if val { _Concurrency.Task { await calendarManager.requestAccess() } }
                        else { showingRevokeAlert = true }
                    }))
                    .toggleStyle(.switch)
                }

                if calendarManager.isAuthorized {
                    Divider()

                    Picker("School Calendar", selection: $calendarManager.selectedCalendarID) {
                        Text("Select a Calendar").tag("")
                        ForEach(calendarManager.availableCalendars, id: \.calendarIdentifier) { cal in
                            HStack {
                                let calColor = (cal.cgColor != nil ? (NSColor(cgColor: cal.cgColor!) ?? NSColor.controlAccentColor) : NSColor.controlAccentColor)
                                Circle().fill(Color(nsColor: calColor)).frame(width: 8, height: 8)
                                Text(cal.title)
                            }
                            .tag(cal.calendarIdentifier)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: calendarManager.selectedCalendarID) { _, _ in _Concurrency.Task { await calendarManager.refreshAll() } }

                    Picker("School Reminders", selection: $calendarManager.selectedReminderListID) {
                        Text("Select a List").tag("")
                        ForEach(calendarManager.availableReminderLists, id: \.calendarIdentifier) { list in
                            HStack {
                                let listColor = (list.cgColor != nil ? (NSColor(cgColor: list.cgColor!) ?? NSColor.controlAccentColor) : NSColor.controlAccentColor)
                                Circle().fill(Color(nsColor: listColor)).frame(width: 8, height: 8)
                                Text(list.title)
                            }
                            .tag(list.calendarIdentifier)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: calendarManager.selectedReminderListID) { _, _ in _Concurrency.Task { await calendarManager.refreshAll() } }

                    Text("Only events and tasks from these specific lists will appear in Roots.")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Workday") {
                DatePicker("Start", selection: Binding(
                    get: { settings.date(from: settings.defaultWorkdayStart) },
                    set: { settings.defaultWorkdayStart = settings.components(from: $0); settings.save() }
                ), displayedComponents: .hourAndMinute)

                DatePicker("End", selection: Binding(
                    get: { settings.date(from: settings.defaultWorkdayEnd) },
                    set: { settings.defaultWorkdayEnd = settings.components(from: $0); settings.save() }
                ), displayedComponents: .hourAndMinute)
            }
        }
        .listStyle(.sidebar)
        .alert("Disable Sync", isPresented: $showingRevokeAlert) {
            Button("Open System Settings") {
                calendarManager.openSystemPrivacySettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To disconnect Roots from your Calendar, please revoke access in System Settings.")
        }
        .onAppear {
            // Load current values
            userName = settings.userName ?? ""
            startOfWeek = StartOfWeek(rawValue: settings.startOfWeek ?? "Sunday") ?? .sunday
            defaultView = DefaultView(rawValue: settings.defaultView ?? "Dashboard") ?? .dashboard
            _Concurrency.Task { await calendarManager.refreshAuthStatus() }
        }
    }

    private func statusDescription(for status: EKAuthorizationStatus) -> String {
        switch status {
        case .authorized, .fullAccess: return "Authorized"
        case .writeOnly: return "Write-only"
        case .denied, .restricted: return "Denied"
        case .notDetermined: return "Not determined"
        @unknown default: return "Unknown"
        }
    }
}

#Preview {
    GeneralSettingsView()
        .environmentObject(AppSettingsModel.shared)
        .environmentObject(CalendarManager.shared)
        .environmentObject(TimerManager())
        
        .frame(width: 500, height: 600)
}
