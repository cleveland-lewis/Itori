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
    
    enum PlannerLookahead: String, CaseIterable, Identifiable {
        case oneWeek = "1w"
        case twoWeeks = "2w"
        case oneMonth = "1m"
        case twoMonths = "2m"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .oneWeek: return NSLocalizedString("settings.planner.lookahead.1week", comment: "1 Week")
            case .twoWeeks: return NSLocalizedString("settings.planner.lookahead.2weeks", comment: "2 Weeks")
            case .oneMonth: return NSLocalizedString("settings.planner.lookahead.1month", comment: "1 Month")
            case .twoMonths: return NSLocalizedString("settings.planner.lookahead.2months", comment: "2 Months")
            }
        }
    }

    @State private var startOfWeek: StartOfWeek = .sunday
    @State private var defaultView: DefaultView = .dashboard
    @State private var plannerLookahead: PlannerLookahead = .twoWeeks

    var body: some View {
        Form {
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
                
                Picker("Scheduler Lookahead", selection: $plannerLookahead) {
                    ForEach(PlannerLookahead.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .onChange(of: plannerLookahead) { _, newValue in
                    settings.plannerHorizon = newValue.rawValue
                    settings.save()
                }
            }

            Section("Display") {
                Toggle(NSLocalizedString("settings.toggle.24hour.time", value: "24-Hour Time", comment: "24-Hour Time"), isOn: $settings.use24HourTime)
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
                Toggle(NSLocalizedString("settings.toggle.enable.autoreschedule", value: "Enable Auto-Reschedule", comment: "Enable Auto-Reschedule"), isOn: Binding(
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
                        Text(NSLocalizedString("settings.check.interval", value: "Check Interval", comment: "Check Interval"))
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
                            Text(verbatim: "\(settings.autoRescheduleCheckInterval) min")
                                .frame(minWidth: 60, alignment: .trailing)
                        }
                    }
                    
                    Toggle(NSLocalizedString("settings.toggle.allow.pushing.lower.priority.tasks", value: "Allow Pushing Lower Priority Tasks", comment: "Allow Pushing Lower Priority Tasks"), isOn: Binding(
                        get: { settings.autoReschedulePushLowerPriority },
                        set: { settings.autoReschedulePushLowerPriority = $0; settings.save() }
                    ))
                    .help("Move lower priority tasks to make room for high-priority missed tasks")
                    
                    if settings.autoReschedulePushLowerPriority {
                        HStack {
                            Text(NSLocalizedString("settings.max.tasks.to.push", value: "Max Tasks to Push", comment: "Max Tasks to Push"))
                            Spacer()
                            Stepper(value: Binding(
                                get: { settings.autoRescheduleMaxPushCount },
                                set: { newValue in
                                    settings.autoRescheduleMaxPushCount = max(0, min(5, newValue))
                                    settings.save()
                                }
                            ), in: 0...5) {
                                Text(verbatim: "\(settings.autoRescheduleMaxPushCount)")
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
                    Text(NSLocalizedString("settings.reset.all.data", value: "Reset All Data", comment: "Reset All Data"))
                        .fontWeight(.semibold)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
        .onAppear {
            startOfWeek = StartOfWeek(rawValue: settings.startOfWeek) ?? .sunday
            defaultView = DefaultView(rawValue: settings.defaultView) ?? .dashboard
            plannerLookahead = PlannerLookahead(rawValue: settings.plannerHorizon) ?? .twoWeeks
        }
        .sheet(isPresented: $showResetSheet) {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString("settings.reset.all.data", value: "Reset All Data", comment: "Reset All Data"))
                        .font(.title2.weight(.bold))
                    Text(NSLocalizedString("settings.this.will.remove.all.app", value: "This will remove all app data including courses, assignments, settings, and cached sessions. This action cannot be undone.", comment: "This will remove all app data including courses, a..."))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(NSLocalizedString("settings.type.the.code.to.confirm", value: "Type the code to confirm", comment: "Type the code to confirm"))
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
                    Button(NSLocalizedString("settings.button.cancel", value: "Cancel", comment: "Cancel")) { showResetSheet = false }
                        .buttonStyle(.bordered)
                    Spacer()
                    Button(NSLocalizedString("settings.button.reset.now", value: "Reset Now", comment: "Reset Now")) {
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
