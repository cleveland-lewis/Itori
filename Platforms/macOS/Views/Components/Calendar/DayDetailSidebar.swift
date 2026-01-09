import SwiftUI

struct DayDetailSidebar: View {
    var date: Date
    var events: [CalendarEvent]
    var onSelectEvent: (CalendarEvent) -> Void = { _ in }

    private let width: CGFloat = 280
    private let calendar = Calendar.current
    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            Divider()
            eventsSection
            Spacer()
        }
        .frame(width: width)
        .sidebarCardStyle()
        .padding(.vertical, 4)
        .focusable()
        .onKeyPress(.upArrow) {
            if !events.isEmpty {
                selectedIndex = max(0, selectedIndex - 1)
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if !events.isEmpty {
                selectedIndex = min(events.count - 1, selectedIndex + 1)
            }
            return .handled
        }
        .onKeyPress(.return) {
            if selectedIndex < events.count {
                onSelectEvent(events[selectedIndex])
            }
            return .handled
        }
        .onChange(of: events) { _, newEvents in
            if selectedIndex >= newEvents.count {
                selectedIndex = max(0, newEvents.count - 1)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(NSLocalizedString("ui.selected.date", value: "SELECTED DATE", comment: "SELECTED DATE"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(date.formatted(.dateTime.weekday().month().day()))
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    @ViewBuilder
    private var eventsSection: some View {
        ScrollView {
            if events.isEmpty {
                emptyStateView
            } else {
                eventsList
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text(String.localizedStringWithFormat(
                NSLocalizedString("events_count", comment: ""),
                0
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var eventsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                Button {
                    selectedIndex = index
                    onSelectEvent(event)
                } label: {
                    DayDetailEventRow(
                        event: event,
                        isSelected: selectedIndex == index,
                        timeRange: timeRange(for: event),
                        categoryLabel: categoryLabel(for: event.category),
                        categoryColor: categoryColor(for: event.category)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .onAppear {
            if !events.isEmpty {
                selectedIndex = 0
            }
        }
    }

    private func timeRange(for event: CalendarEvent) -> String {
        let use24 = AppSettingsModel.shared.use24HourTime
        let f = DateFormatter()
        f.dateFormat = use24 ? "HH:mm" : "h:mm a"
        return "\(f.string(from: event.startDate)) - \(f.string(from: event.endDate))"
    }

    private func categoryLabel(for category: EventCategory) -> String {
        switch category {
        case .exam: "Exam"
        case .class: "Class"
        case .homework: "Homework"
        case .reading: "Reading"
        case .review: "Review"
        case .study: "Study"
        case .lab: "Lab"
        case .other: "Event"
        }
    }

    private func categoryLabel(for category: EventCategoryStub?) -> String {
        categoryLabel(for: mapStubCategory(category))
    }

    private func categoryColor(for category: EventCategory) -> Color {
        switch category {
        case .exam: .red
        case .class: .blue
        case .homework: .orange
        case .reading: .yellow
        case .review: .purple
        case .study: .green
        case .lab: .cyan
        case .other: Color(nsColor: .controlAccentColor)
        }
    }

    private func categoryColor(for category: EventCategoryStub?) -> Color {
        categoryColor(for: mapStubCategory(category))
    }

    private func mapStubCategory(_ category: EventCategoryStub?) -> EventCategory {
        switch category {
        case .homework:
            .homework
        case .classSession:
            .class
        case .study:
            .study
        case .exam:
            .exam
        case .meeting:
            .other
        case .other, .none:
            .other
        }
    }
}

private struct DayDetailEventRow: View {
    let event: CalendarEvent
    let isSelected: Bool
    let timeRange: String
    let categoryLabel: String
    let categoryColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(categoryColor)
                .frame(width: 6)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(event.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Spacer()

                    Text(categoryLabel)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(categoryColor.opacity(0.15))
                        )
                }

                Text(timeRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let location = event.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(location)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

struct DayDetailSidebar_Previews: PreviewProvider {
    static var sampleEvents: [CalendarEvent] = [
        CalendarEvent(
            title: "Dentist Appointment",
            startDate: Date().addingTimeInterval(3600),
            endDate: Date().addingTimeInterval(5400),
            location: "Dental Office"
        ),
        CalendarEvent(
            title: "Study Group",
            startDate: Date().addingTimeInterval(7200),
            endDate: Date().addingTimeInterval(9000),
            location: "Library"
        )
    ]

    static var previews: some View {
        Group {
            DayDetailSidebar(date: Date(), events: sampleEvents, onSelectEvent: { _ in })
                .previewLayout(.sizeThatFits)
                .padding()

            DayDetailSidebar(date: Date(), events: [], onSelectEvent: { _ in })
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
}
