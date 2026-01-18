#if os(macOS)
    import SwiftUI

    struct SettingsView: View {
        @Environment(\.colorScheme) var colorScheme
        @EnvironmentObject var settings: AppSettingsModel
        @EnvironmentObject var coursesStore: CoursesStore
        @EnvironmentObject var assignmentsStore: AssignmentsStore
        // design tokens
        @State private var selectedMaterial: DesignMaterial = .regular
        @State private var diagnosticReport: DiagnosticReport? = nil
        @State private var showingHealthCheck = false
        @State private var saveWorkItem: DispatchWorkItem?

        var body: some View {
            NavigationView {
                List {
                    Section(header: Text(NSLocalizedString("settings.general", value: "General", comment: "General"))) {
                        Toggle(
                            NSLocalizedString(
                                "settings.toggle.use.24hour.time",
                                value: "Use 24-hour time",
                                comment: "Use 24-hour time"
                            ),
                            isOn: $settings.use24HourTime
                        )
                        Toggle(
                            NSLocalizedString(
                                "settings.toggle.high.contrast.mode",
                                value: "High Contrast Mode",
                                comment: "High Contrast Mode"
                            ),
                            isOn: $settings.highContrastMode
                        )
                    }

                    Section(header: Text(NSLocalizedString(
                        "settings.academic",
                        value: "Academic",
                        comment: "Academic"
                    ))) {
                        // Note: Courses & Semesters management now handled via SettingsRootView
                        // NavigationLink(destination: CoursesSettingsView().environmentObject(coursesStore)) {
                        //     Label(NSLocalizedString("settings.label.courses.semesters", value: "Courses & Semesters",
                        //     comment: "Courses & Semesters"), systemImage: "book.closed")
                        // }
                    }

                    Section(header: Text(NSLocalizedString("settings.workday", value: "Workday", comment: "Workday"))) {
                        DatePicker("Start", selection: Binding(
                            get: { settings.date(from: settings.defaultWorkdayStart) },
                            set: { settings.defaultWorkdayStart = settings.components(from: $0) }
                        ), displayedComponents: [.hourAndMinute])
                        DatePicker("End", selection: Binding(
                            get: { settings.date(from: settings.defaultWorkdayEnd) },
                            set: { settings.defaultWorkdayEnd = settings.components(from: $0) }
                        ), displayedComponents: [.hourAndMinute])
                        HStack(alignment: .center) {
                            Text("Days")
                            Spacer(minLength: 12)
                            HStack(spacing: 6) {
                                ForEach(weekdayOptions, id: \.index) { day in
                                    Button(day.label) {
                                        toggleWorkday(day.index)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(
                                                settings.workdayWeekdays.contains(day.index)
                                                    ? Color.accentColor.opacity(0.2)
                                                    : Color.secondary.opacity(0.1)
                                            )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                settings.workdayWeekdays.contains(day.index)
                                                    ? Color.accentColor
                                                    : Color.secondary.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                                }
                            }
                        }
                    }

                    Section(header: Text(NSLocalizedString(
                        "settings.advanced",
                        value: "Advanced",
                        comment: "Advanced"
                    ))) {
                        NavigationLink(destination: DebugSettingsView(selectedMaterial: $selectedMaterial)) {
                            Label(
                                NSLocalizedString("settings.label.developer", value: "Developer", comment: "Developer"),
                                systemImage: "hammer"
                            )
                        }
                    }

                    Section(header: Text(NSLocalizedString("settings.design", value: "Design", comment: "Design"))) {
                        Picker("Material", selection: $selectedMaterial) {
                            ForEach(DesignSystem.materials, id: \.id) { token in
                                Text(token.name).tag(token as DesignMaterial)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section {
                        Button {
                            diagnosticReport = AppDebugger.shared.runFullDiagnostic(
                                dataManager: coursesStore,
                                calendarManager: CalendarManager.shared,
                                assignmentsStore: assignmentsStore
                            )
                            showingHealthCheck = true
                        } label: {
                            Label(
                                NSLocalizedString(
                                    "settings.label.run.health.check",
                                    value: "Run Health Check",
                                    comment: "Run Health Check"
                                ),
                                systemImage: "stethoscope"
                            )
                        }
                    } footer: {
                        Text(NSLocalizedString(
                            "settings.runs.a.quick.selfdiagnostic.across",
                            value: "Runs a quick self-diagnostic across data, permissions, and local files.",
                            comment: "Runs a quick self-diagnostic across data, permissi..."
                        ))
                    }
                }
                #if os(iOS)
                    #if os(iOS)
                        .listStyle(.insetGrouped)
                    #else
                        .listStyle(.plain)
                    #endif
                #else
                        .listStyle(.plain)
                #endif
                        .navigationTitle("Settings")
                        .onChange(of: settings.use24HourTime) { _, _ in scheduleSettingsSave() }
                        .onChange(of: settings.highContrastMode) { _, _ in scheduleSettingsSave() }
                        .onChange(of: settings.defaultWorkdayStart) { _, _ in scheduleSettingsSave() }
                        .onChange(of: settings.defaultWorkdayEnd) { _, _ in scheduleSettingsSave() }
            }
            .background(DesignSystem.Colors.appBackground)
            .alert("Health Check", isPresented: $showingHealthCheck, presenting: diagnosticReport) { _ in
                Button(NSLocalizedString("OK", value: "OK", comment: ""), role: .cancel) {}
            } message: { report in
                if report.issues.isEmpty {
                    Text(NSLocalizedString(
                        "settings.all.systems.look.healthy",
                        value: "All systems look healthy.",
                        comment: "All systems look healthy."
                    ))
                } else {
                    Text(report.formattedSummary)
                }
            }
        }

        private func scheduleSettingsSave() {
            saveWorkItem?.cancel()
            let work = DispatchWorkItem { settings.save() }
            saveWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
        }

        private var weekdayOptions: [(index: Int, label: String)] {
            Calendar.current.shortWeekdaySymbols.enumerated().map { idx, label in
                (index: idx + 1, label: label)
            }
        }

        private func toggleWorkday(_ index: Int) {
            var days = Set(settings.workdayWeekdays)
            if days.contains(index) {
                if days.count == 1 { return }
                days.remove(index)
            } else {
                days.insert(index)
            }
            settings.workdayWeekdays = Array(days).sorted()
            scheduleSettingsSave()
        }
    }

    private struct DebugSettingsView: View {
        @Binding var selectedMaterial: DesignMaterial

        var body: some View {
            Form {
                Toggle(
                    NSLocalizedString(
                        "settings.toggle.enable.verbose.logging",
                        value: "Enable verbose logging",
                        comment: "Enable verbose logging"
                    ),
                    isOn: .constant(false)
                )
                Button(NSLocalizedString(
                    "settings.button.reset.demo.data",
                    value: "Reset demo data",
                    comment: "Reset demo data"
                )) {}

                Section(header: Text(NSLocalizedString(
                    "settings.design.debug",
                    value: "Design debug",
                    comment: "Design debug"
                ))) {
                    HStack {
                        Text(NSLocalizedString(
                            "settings.selected.material",
                            value: "Selected material",
                            comment: "Selected material"
                        ))
                        Spacer()
                        Text(selectedMaterial.name)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Developer")
        }
    }

    #if !DISABLE_PREVIEWS
        #if !DISABLE_PREVIEWS
            #Preview {
                SettingsView()
            }
        #endif
    #endif
#endif
