#if os(macOS)
    import EventKit
    import SwiftUI

    struct CalendarDayView: View {
        let date: Date
        let events: [EKEvent]
        var onSelectEvent: ((EKEvent) -> Void)?

        @Environment(\.colorScheme) private var colorScheme
        @EnvironmentObject private var settings: AppSettingsModel

        private let calendar = Calendar.current
        private let hourHeight: CGFloat = 60
        private let hours = Array(0 ... 23)

        var body: some View {
            ScrollViewReader { proxy in
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        // Time grid with hour labels
                        timeGrid

                        // Events overlay
                        eventBars
                    }
                    .padding(.leading, 60)
                    .padding(.trailing, 16)
                    .padding(.vertical, 8)
                }
                .onAppear {
                    // Scroll to 8 AM by default
                    proxy.scrollTo(8, anchor: .top)
                }
            }
        }

        private var timeGrid: some View {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(hours, id: \.self) { hour in
                    HStack(alignment: .top, spacing: 12) {
                        // Hour label
                        Text(formatHour(hour))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .trailing)
                            .offset(x: -62, y: -8)

                        // Hour line
                        Rectangle()
                            .fill(DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.2))
                            .frame(height: 1)
                    }
                    .frame(height: hourHeight, alignment: .top)
                    .id(hour)
                }
            }
        }

        private var eventBars: some View {
            GeometryReader { geometry in
                let dayStart = calendar.startOfDay(for: date)

                ForEach(sortedEvents, id: \.eventIdentifier) { event in
                    if let startOffset = timeOffset(for: event.startDate, relativeTo: dayStart) {
                        let duration = event.endDate.timeIntervalSince(event.startDate)

                        Button {
                            onSelectEvent?(event)
                        } label: {
                            EventBar(event: event)
                                .frame(width: geometry.size.width - 16)
                                .frame(height: max(20, CGFloat(duration / 3600) * hourHeight - 4))
                        }
                        .buttonStyle(.plain)
                        .offset(x: 8, y: startOffset)
                    }
                }
            }
        }

        private var sortedEvents: [EKEvent] {
            events.sorted { $0.startDate < $1.startDate }
        }

        private func timeOffset(for time: Date, relativeTo dayStart: Date) -> CGFloat? {
            let interval = time.timeIntervalSince(dayStart)
            guard interval >= 0 else { return nil }
            let hours = interval / 3600
            return CGFloat(hours) * hourHeight
        }

        private func formatHour(_ hour: Int) -> String {
            let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: self.date) ?? self.date
            let formatter = DateFormatter()
            formatter.dateFormat = settings.use24HourTime ? "HH:mm" : "h a"
            return formatter.string(from: date)
        }
    }

    private struct EventBar: View {
        let event: EKEvent
        @State private var isHovered = false

        var body: some View {
            HStack(alignment: .top, spacing: 8) {
                // Category color stripe
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(categoryColor)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)

                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption2)
                            Text(location)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    }

                    Text(timeRange)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
                .padding(.trailing, 8)

                Spacer(minLength: 0)
            }
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(categoryColor.opacity(isHovered ? 0.15 : 0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(categoryColor.opacity(0.3), lineWidth: 1)
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

        private var timeRange: String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            // Override for 24-hour time preference
            if AppSettingsModel.shared.use24HourTime {
                formatter.dateFormat = "HH:mm"
            }
            return "\(formatter.string(from: event.startDate)) – \(formatter.string(from: event.endDate))"
        }
    }
#endif
