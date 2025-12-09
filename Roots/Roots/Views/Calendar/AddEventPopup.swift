import SwiftUI
import EventKit

struct AddEventPopup: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var calendarManager: CalendarManager

    @State private var title: String = ""
    @State private var location: String = ""
    @State private var isAllDay: Bool = false
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)
    @State private var notes: String = ""
    @State private var selectedCalendar: EKCalendar?

    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        RootsPopupContainer(title: "New Event", subtitle: nil) {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    titleLocationSection
                    timeSection
                    calendarSection
                    notesSection
                    if let error = errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(DesignSystem.Typography.caption)
                    }
                }
                .padding(DesignSystem.Spacing.large)
            }
            .frame(width: 450, height: 520)
            .onAppear {
                selectedCalendar = calendarManager.defaultCalendarForNewEvents
            }
        } footer: {
            footer
        }
    }

    private var formContent: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.large) {
                titleLocationSection
                timeSection
                calendarSection
                notesSection
            }
            .padding(DesignSystem.Spacing.large)
        }
    }

    private var titleLocationSection: some View {
        RootsCard {
            VStack(spacing: DesignSystem.Spacing.medium) {
                TextField("Event Title", text: $title)
                    .font(DesignSystem.Typography.subHeader)
                    .textFieldStyle(.plain)
                    .padding(DesignSystem.Layout.spacing.small)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)

                Divider()

                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.secondary)
                    TextField("Location or Video Call", text: $location)
                        .textFieldStyle(.plain)
                }
                .padding(4)
            }
            .padding(DesignSystem.Spacing.medium)
        }
    }

    private var timeSection: some View {
        RootsCard {
            VStack(spacing: DesignSystem.Spacing.medium) {
                Toggle("All-day", isOn: $isAllDay)
                    .toggleStyle(.switch)

                Divider()

                DatePicker("Starts", selection: $startDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])

                DatePicker("Ends", selection: $endDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
            }
            .padding(DesignSystem.Spacing.medium)
        }
    }

    private var calendarSection: some View {
        RootsCard {
            HStack {
                Text("Calendar")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $selectedCalendar) {
                    Text("Default").tag(nil as EKCalendar?)
                    ForEach(calendarManager.writableCalendars, id: \.calendarIdentifier) { calendar in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(nsColor: calendar.color))
                                .frame(width: 8, height: 8)
                            Text(calendar.title)
                        }
                        .tag(calendar as EKCalendar?)
                    }
                }
                .labelsHidden()
                .fixedSize()
            }
            .padding(DesignSystem.Spacing.medium)
        }
    }

    private var notesSection: some View {
        RootsCard {
            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                Text("Notes")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $notes)
                    .font(.body)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .padding(DesignSystem.Spacing.medium)
        }
    }

    private var footer: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            Button(action: saveEvent) {
                HStack {
                    if isSaving {
                        ProgressView().controlSize(.small)
                    }
                    Text("Add Event")
                }
                .frame(minWidth: 100)
            }
            .buttonStyle(RootsLiquidButtonStyle())
            .disabled(title.isEmpty || isSaving)
            .keyboardShortcut(.defaultAction)
        }
        .padding(DesignSystem.Spacing.large)
        .background(DesignSystem.Materials.popup)
    }

    private func saveEvent() {
        guard !title.isEmpty else { return }
        isSaving = true

        _Concurrency.Task {
            do {
                try await calendarManager.saveEvent(
                    title: title,
                    startDate: startDate,
                    endDate: endDate,
                    isAllDay: isAllDay,
                    location: location,
                    notes: notes,
                    calendar: selectedCalendar
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save: \(error.localizedDescription)"
                    isSaving = false
                }
            }
        }
    }
}
