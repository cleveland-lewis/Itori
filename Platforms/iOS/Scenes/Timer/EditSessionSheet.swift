#if os(iOS)
    import SwiftUI

    struct EditSessionSheet: View {
        @ObservedObject var viewModel: TimerPageViewModel
        @Environment(\.dismiss) private var dismiss

        private let session: FocusSession
        @State private var startDate: Date
        @State private var endDate: Date

        init(session: FocusSession, viewModel: TimerPageViewModel) {
            self.session = session
            self.viewModel = viewModel
            let start = session.startedAt ?? Date()
            let defaultDuration = session.actualDuration
                ?? session.plannedDuration
                ?? 0
            let end = session.endedAt ?? start.addingTimeInterval(defaultDuration)
            _startDate = State(initialValue: start)
            _endDate = State(initialValue: end)
        }

        var body: some View {
            NavigationStack {
                Form {
                    Section {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("Start Time", selection: $startDate, displayedComponents: .hourAndMinute)
                    }
                    Section {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        DatePicker("End Time", selection: $endDate, displayedComponents: .hourAndMinute)
                    }
                    if endDate < startDate {
                        Text(NSLocalizedString(
                            "End time must be after the start time.",
                            value: "End time must be after the start time.",
                            comment: ""
                        ))
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
                .navigationTitle("Edit Session")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(NSLocalizedString("Cancel", value: "Cancel", comment: "")) { dismiss() }
                            .accessibilityLabel(NSLocalizedString(
                                "ui.button.cancel",
                                value: "Cancel",
                                comment: "Cancel button"
                            ))
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(NSLocalizedString("Save", value: "Save", comment: "")) { saveChanges() }
                            .disabled(endDate < startDate)
                            .accessibilityLabel(NSLocalizedString(
                                "ui.button.save",
                                value: "Save",
                                comment: "Save button"
                            ))
                            .accessibilityHint(NSLocalizedString(
                                "editsession.save.hint",
                                value: "Saves the updated session times",
                                comment: "Hint for save button"
                            ))
                    }
                }
            }
        }

        private func saveChanges() {
            var updated = session
            updated.startedAt = startDate
            updated.endedAt = endDate
            updated.actualDuration = max(endDate.timeIntervalSince(startDate), 0)
            updated.state = .completed
            viewModel.updateSession(updated)
            dismiss()
        }
    }
#endif
