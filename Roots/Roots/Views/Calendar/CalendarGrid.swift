import SwiftUI
import EventKit

struct CalendarGrid: View {
    @Binding var currentMonth: Date
    var events: [EKEvent]
    @EnvironmentObject private var calendarManager: CalendarManager

    private let calendar = Calendar.current

    var body: some View {
        let days = makeDays()
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
            ForEach(days, id: \.self) { day in
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(calendar.component(.day, from: day))")
                        .font(.caption.bold())
                        .foregroundStyle(calendar.isDate(day, equalTo: Date(), toGranularity: .day) ? Color.accentColor : .secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    let dayEvents = eventsForDay(day)
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(dayEvents.prefix(3), id: \.rootsIdentifier) { event in
                            Text(event.title)
                                .font(.caption2)
                                .lineLimit(1)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        if dayEvents.count > 3 {
                            Text("+\(dayEvents.count - 3) more")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(8)
                .frame(minHeight: 120, alignment: .topLeading)
                .frame(maxHeight: .infinity, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    private func makeDays() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        var start = calendar.date(from: calendar.dateComponents([.year, .month], from: monthInterval.start))!

        // start from Sunday of first week
        let weekday = calendar.component(.weekday, from: start)
        let delta = weekday - calendar.firstWeekday
        if delta > 0 {
            start = calendar.date(byAdding: .day, value: -delta, to: start)!
        }

        var days: [Date] = []
        for offset in 0..<42 { // 6 weeks grid
            if let date = calendar.date(byAdding: .day, value: offset, to: start) {
                days.append(date)
            }
        }
        return days
    }

    private func eventsForDay(_ date: Date) -> [EKEvent] {
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        return events.filter { $0.startDate >= start && $0.startDate < end }
    }
}
