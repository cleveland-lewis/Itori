#if os(macOS)
    import EventKit
    import SwiftUI

    struct CalendarWeekView: View {
        let currentDate: Date
        let events: [EKEvent]
        var onSelectEvent: ((EKEvent) -> Void)?

        @Environment(\.colorScheme) private var colorScheme
        @EnvironmentObject private var settings: AppSettingsModel

        private let calendar = Calendar.current
        private let hourHeight: CGFloat = 60
        private let hours = Array(0 ... 23)

        private var weekDays: [Date] {
            let start = calendar.date(from: calendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear],
                from: currentDate
            )) ?? currentDate
            return (0 ..< 7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        }

        var body: some View {
            VStack(spacing: 0) {
                // Week header with day labels
                weekHeader
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                Divider()

                // Main calendar grid
                ScrollViewReader { proxy in
                    ScrollView {
                        ZStack(alignment: .topLeading) {
                            // Time grid
                            timeGrid

                            // Events overlay for each day
                            eventsGrid
                        }
                        .padding(.vertical, 8)
                    }
                    .onAppear {
                        // Scroll to 8 AM
                        proxy.scrollTo(8, anchor: .top)
                    }
                }
            }
        }

        private var weekHeader: some View {
            HStack(spacing: 0) {
                // Time label spacer
                Spacer()
                    .frame(width: 60)

                // Day columns
                ForEach(weekDays, id: \.self) { day in
                    VStack(spacing: 4) {
                        Text(weekdaySymbol(for: day))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(verbatim: "\(calendar.component(.day, from: day))")
                            .font(.title3.weight(calendar.isDateInToday(day) ? .bold : .regular))
                            .foregroundStyle(calendar.isDateInToday(day) ? Color.accentColor : Color.primary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(calendar.isDateInToday(day) ? .accentQuaternary : Color.clear)
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }

        private var timeGrid: some View {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(hours, id: \.self) { hour in
                    HStack(alignment: .top, spacing: 0) {
                        // Hour label
                        Text(formatHour(hour))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                            .padding(.trailing, 8)
                            .offset(y: -8)

                        // Hour line across all days
                        Rectangle()
                            .fill(DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.15))
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                    }
                    .frame(height: hourHeight, alignment: .top)
                    .id(hour)
                }
            }
        }

        private var eventsGrid: some View {
            GeometryReader { geometry in
                let timeColumnWidth: CGFloat = 60
                let dayWidth = (geometry.size.width - timeColumnWidth - 32) / 7

                ForEach(Array(weekDays.enumerated()), id: \.element) { index, day in
                    let dayEvents = events(for: day)
                    let dayStart = calendar.startOfDay(for: day)

                    ZStack(alignment: .topLeading) {
                        ForEach(dayEvents, id: \.eventIdentifier) { event in
                            if let startOffset = timeOffset(for: event.startDate, relativeTo: dayStart) {
                                let duration = event.endDate.timeIntervalSince(event.startDate)

                                Button {
                                    onSelectEvent?(event)
                                } label: {
                                    WeekEventBar(event: event, isNarrow: dayWidth < 100)
                                        .frame(width: dayWidth - 8)
                                        .frame(height: max(16, CGFloat(duration / 3600) * hourHeight - 4))
                                }
                                .buttonStyle(.plain)
                                .offset(x: timeColumnWidth + 16 + CGFloat(index) * dayWidth + 4, y: startOffset)
                            }
                        }
                    }
                }
            }
        }

        private func events(for day: Date) -> [EKEvent] {
            events.filter { calendar.isDate($0.startDate, inSameDayAs: day) }
                .sorted { $0.startDate < $1.startDate }
        }

        private func timeOffset(for time: Date, relativeTo dayStart: Date) -> CGFloat? {
            let interval = time.timeIntervalSince(dayStart)
            guard interval >= 0 else { return nil }
            let hours = interval / 3600
            return CGFloat(hours) * hourHeight
        }

        private func formatHour(_ hour: Int) -> String {
            let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: currentDate) ?? currentDate
            let formatter = DateFormatter()
            formatter.dateFormat = settings.use24HourTime ? "HH:mm" : "h a"
            return formatter.string(from: date)
        }

        private func weekdaySymbol(for date: Date) -> String {
            calendar.shortWeekdaySymbols[(calendar.component(.weekday, from: date) - 1 + 7) % 7]
        }
    }

    private struct WeekEventBar: View {
        let event: EKEvent
        let isNarrow: Bool
        @State private var isHovered = false

        var body: some View {
            VStack(alignment: .leading, spacing: 1) {
                if !isNarrow {
                    Text(event.title)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)

                    if let location = event.location, !location.isEmpty {
                        Text(location)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    // Minimal display for narrow columns
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(isNarrow ? 2 : 4)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(categoryColor.opacity(isHovered ? 0.2 : 0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(categoryColor.opacity(0.4), lineWidth: isNarrow ? 1 : 0.5)
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }

        private var categoryColor: Color {
            if let category = parseEventCategory(from: event.title) {
                return category.color
            }
            return .accentColor
        }
    }
#endif
