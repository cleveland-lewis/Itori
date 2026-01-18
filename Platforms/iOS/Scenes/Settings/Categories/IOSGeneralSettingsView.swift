import Combine
import SwiftUI

#if os(iOS)

    struct IOSGeneralSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel
        @EnvironmentObject var assignmentsStore: AssignmentsStore
        @EnvironmentObject var coursesStore: CoursesStore
        @EnvironmentObject var plannerStore: PlannerStore
        @EnvironmentObject var gradesStore: GradesStore

        @State private var showResetSheet = false
        @State private var resetCode: String = ""
        @State private var resetInput: String = ""
        @State private var didCopyResetCode = false
        @State private var isResetting = false

        var body: some View {
            List {
                Section {
                    Toggle(isOn: binding(for: \.use24HourTimeStorage)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("settings.general.use_24h", comment: "Use 24-Hour Time"))
                            Text(NSLocalizedString(
                                "settings.general.use_24h.detail",
                                comment: "Display times in 24-hour format"
                            ))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    HStack {
                        Text(NSLocalizedString("settings.general.workday_start", comment: "Workday Start"))
                        Spacer()
                        Picker("", selection: binding(for: \.workdayStartHourStorage)) {
                            ForEach(0 ..< 24) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .labelsHidden()
                    }

                    HStack {
                        Text(NSLocalizedString("settings.general.workday_end", comment: "Workday End"))
                        Spacer()
                        Picker("", selection: binding(for: \.workdayEndHourStorage)) {
                            ForEach(0 ..< 24) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("settings.general.workday_days", value: "Days", comment: "Days"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            ForEach(weekdayOptions, id: \.index) { day in
                                Button {
                                    toggleWorkday(day.index)
                                } label: {
                                    Text(day.label)
                                        .font(.caption.weight(.medium))
                                        .frame(minWidth: 32)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 4)
                                        .background(
                                            Capsule()
                                                .fill(settings.workdayWeekdays.contains(day.index)
                                                    ? Color.accentColor.opacity(0.2)
                                                    : Color.secondary.opacity(0.1))
                                        )
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(
                                                    settings.workdayWeekdays.contains(day.index)
                                                        ? Color.accentColor
                                                        : Color.secondary.opacity(0.3),
                                                    lineWidth: 1.5
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(NSLocalizedString("settings.general.workday.header", comment: "Workday Hours"))
                } footer: {
                    Text(NSLocalizedString(
                        "settings.general.workday.footer",
                        comment: "Affects planner scheduling and energy tracking"
                    ))
                }

                Section(NSLocalizedString(
                    "settings.general.reset.header",
                    value: "Reset Data",
                    comment: "Reset data header"
                )) {
                    Button(role: .destructive) {
                        resetInput = ""
                        showResetSheet = true
                    } label: {
                        Text(NSLocalizedString(
                            "settings.general.reset.action",
                            value: "Reset All Data",
                            comment: "Reset all data"
                        ))
                        .fontWeight(.semibold)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(NSLocalizedString("settings.category.general", comment: "General"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showResetSheet) {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString(
                            "settings.general.reset.title",
                            value: "Reset All Data",
                            comment: "Reset all data title"
                        ))
                        .font(.title2.weight(.bold))
                        Text(NSLocalizedString(
                            "settings.general.reset.message",
                            value: "This will remove all app data including courses, assignments, settings, and cached sessions. This action cannot be undone.",
                            comment: "Reset all data message"
                        ))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(NSLocalizedString(
                            "settings.general.reset.code.prompt",
                            value: "Type the code to confirm",
                            comment: "Reset confirmation prompt"
                        ))
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
                                Text(didCopyResetCode
                                    ? NSLocalizedString("common.copied", value: "Copied", comment: "Copied")
                                    : NSLocalizedString("common.copy", value: "Copy", comment: "Copy"))
                                    .font(.caption.weight(.semibold))
                            }
                            .buttonStyle(.itoriLiquidProminent)
                            .controlSize(.small)
                            Spacer()
                        }
                        TextField(
                            NSLocalizedString(
                                "settings.general.reset.code.placeholder",
                                value: "Enter code exactly",
                                comment: "Reset code placeholder"
                            ),
                            text: $resetInput
                        )
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .disableAutocorrection(true)
                    }

                    HStack(spacing: 12) {
                        Button(NSLocalizedString("common.cancel", comment: "Cancel")) { showResetSheet = false }
                            .buttonStyle(.itariLiquid)
                        Spacer()
                        Button(NSLocalizedString(
                            "settings.general.reset.confirm",
                            value: "Reset Now",
                            comment: "Reset now"
                        )) {
                            performReset()
                        }
                        .buttonStyle(.itoriLiquidProminent)
                        .tint(.red)
                        .disabled(!resetCodeMatches || isResetting)
                    }
                }
                .padding(26)
                .frame(maxWidth: 520)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(DesignSystem.Materials.card)
                )
                .padding()
                .presentationDetents([.medium])
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
                    isResetting = false
                }
            }
        }

        private func formatHour(_ hour: Int) -> String {
            if settings.use24HourTime {
                return String(format: "%02d:00", hour)
            } else {
                let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
                let period = hour < 12 ? NSLocalizedString("time.am", comment: "AM") : NSLocalizedString(
                    "time.pm",
                    comment: "PM"
                )
                return "\(displayHour):00 \(period)"
            }
        }

        private func binding<Value>(for keyPath: ReferenceWritableKeyPath<AppSettingsModel, Value>) -> Binding<Value> {
            Binding(
                get: { settings[keyPath: keyPath] },
                set: { newValue in
                    settings.objectWillChange.send()
                    settings[keyPath: keyPath] = newValue
                    settings.save()
                }
            )
        }

        private func performReset() {
            guard resetCodeMatches else { return }
            isResetting = true
            AppModel.shared.requestReset()
            showResetSheet = false
            isResetting = false
        }

        private var resetCodeMatches: Bool {
            resetInput.trimmingCharacters(in: .whitespacesAndNewlines) == resetCode
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
            settings.save()
        }
    }

    #if !DISABLE_PREVIEWS
        #Preview {
            NavigationStack {
                IOSGeneralSettingsView()
                    .environmentObject(AppSettingsModel.shared)
            }
        }
    #endif
#endif
