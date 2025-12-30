#if os(macOS)
import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var assignmentsStore: AssignmentsStore
    @EnvironmentObject var coursesStore: CoursesStore
    @EnvironmentObject var plannerStore: PlannerStore
    @EnvironmentObject var gradesStore: GradesStore

    @State private var showResetSheet = false
    @State private var resetCode: String = ""
    @State private var resetInput: String = ""
    @State private var isResetting = false
    @State private var didCopyResetCode = false

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

    var body: some View {
        Form {
            Section("Study Mode") {
                Toggle(settings.isSchoolMode ? "School Mode" : "Self-Study Mode", isOn: $settings.isSchoolMode)
                    .onChange(of: settings.isSchoolMode) { _, _ in settings.save() }
                
                Text(settings.isSchoolMode 
                     ? "Organize studies with courses, semesters, and assignments" 
                     : "Study independently without course structure")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
            
            Section("Auto-Reschedule") {
                Toggle("Enable Auto-Reschedule", isOn: Binding(
                    get: { settings.enableAutoReschedule },
                    set: { newValue in
                        settings.enableAutoReschedule = newValue
                        settings.save()
                        if newValue {
                            MissedEventDetectionService.shared.startMonitoring()
                        } else {
                            MissedEventDetectionService.shared.stopMonitoring()
                        }
                    }
                ))
                .help("Automatically reschedule missed tasks to available time slots")
                
                if settings.enableAutoReschedule {
                    HStack {
                        Text("Check Interval")
                        Spacer()
                        Stepper(value: Binding(
                            get: { settings.autoRescheduleCheckInterval },
                            set: { newValue in
                                settings.autoRescheduleCheckInterval = max(1, min(60, newValue))
                                settings.save()
                                if settings.enableAutoReschedule {
                                    MissedEventDetectionService.shared.stopMonitoring()
                                    MissedEventDetectionService.shared.startMonitoring()
                                }
                            }
                        ), in: 1...60) {
                            Text("\(settings.autoRescheduleCheckInterval) min")
                                .frame(minWidth: 60, alignment: .trailing)
                        }
                    }
                    
                    Toggle("Allow Pushing Lower Priority Tasks", isOn: Binding(
                        get: { settings.autoReschedulePushLowerPriority },
                        set: { settings.autoReschedulePushLowerPriority = $0; settings.save() }
                    ))
                    .help("Move lower priority tasks to make room for high-priority missed tasks")
                    
                    if settings.autoReschedulePushLowerPriority {
                        HStack {
                            Text("Max Tasks to Push")
                            Spacer()
                            Stepper(value: Binding(
                                get: { settings.autoRescheduleMaxPushCount },
                                set: { newValue in
                                    settings.autoRescheduleMaxPushCount = max(0, min(5, newValue))
                                    settings.save()
                                }
                            ), in: 0...5) {
                                Text("\(settings.autoRescheduleMaxPushCount)")
                                    .frame(minWidth: 30, alignment: .trailing)
                            }
                        }
                    }
                }
                
                Text(settings.enableAutoReschedule 
                     ? "Tasks you've manually edited or locked will never be moved automatically."
                     : "When enabled, missed tasks are automatically rescheduled to keep your schedule current.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Danger Zone") {
                Button(role: .destructive) {
                    resetInput = ""
                    showResetSheet = true
                } label: {
                    Text("Reset All Data")
                        .fontWeight(.semibold)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
        .onAppear {
            startOfWeek = StartOfWeek(rawValue: settings.startOfWeek ?? "Sunday") ?? .sunday
            defaultView = DefaultView(rawValue: settings.defaultView ?? "Dashboard") ?? .dashboard
        }
        .sheet(isPresented: $showResetSheet) {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reset All Data")
                        .font(.title2.weight(.bold))
                    Text("This will remove all app data including courses, assignments, settings, and cached sessions. This action cannot be undone.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Type the code to confirm")
                        .font(.headline.weight(.semibold))
                    HStack {
                        Text(resetCode)
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.red.opacity(0.15))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.red.opacity(0.5), lineWidth: 1)
                            )
                        Button {
                            Clipboard.copy(resetCode)
                            didCopyResetCode = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                didCopyResetCode = false
                            }
                        } label: {
                            Text(didCopyResetCode ? "Copied" : "Copy")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        Spacer()
                    }
                    TextField("Enter code exactly", text: $resetInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .disableAutocorrection(true)
                }

                HStack(spacing: 12) {
                    Button("Cancel") { showResetSheet = false }
                        .buttonStyle(.bordered)
                    Spacer()
                    Button("Reset Now") {
                        performReset()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!resetCodeMatches || isResetting)
                }
            }
            .padding(26)
            .frame(minWidth: 440, maxWidth: 520)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(DesignSystem.Materials.card)
            )
            .padding()
            .onAppear {
                if resetCode.isEmpty {
                    resetCode = ConfirmationCode.generate()
                }
            }
        }
        .onChange(of: showResetSheet) { _, isPresented in
            if !isPresented {
                resetCode = ""
                resetInput = ""
                didCopyResetCode = false
            }
        }
    }

    private func performReset() {
        guard resetCodeMatches else { return }
        isResetting = true
        AppModel.shared.requestReset()
        timerManager.stop()
        // Reset local UI state
        startOfWeek = .sunday
        defaultView = .dashboard
        resetInput = ""
        showResetSheet = false
        isResetting = false
    }

    private var resetCodeMatches: Bool {
        resetInput.trimmingCharacters(in: .whitespacesAndNewlines) == resetCode
    }
}

#if !DISABLE_PREVIEWS
#if !DISABLE_PREVIEWS
#Preview {
    GeneralSettingsView()
        .environmentObject(AppSettingsModel.shared)
        .environmentObject(TimerManager())
        .environmentObject(AssignmentsStore.shared)
        .environmentObject(CoursesStore())
        .frame(width: 500, height: 600)
}
#endif
#endif
#endif
