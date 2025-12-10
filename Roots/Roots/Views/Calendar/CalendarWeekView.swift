import SwiftUI
import EventKit

struct CalendarWeekView: View {
    var currentDate: Date
    var events: [EKEvent]
    var onSelectEvent: ((EKEvent) -> Void)? = nil

    private let calendar = Calendar.current

    private var weekDays: [Date] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start ?? currentDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(weekDays, id: \.self) { day in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(day.formatted(.dateTime.weekday(.abbreviated).day()))
                            .font(.caption.bold())
                            .padding(.vertical, 4)

                        CalendarDayView(date: day, events: eventsForDay(day), onSelectEvent: onSelectEvent)
                            .frame(width: 260)
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private func eventsForDay(_ day: Date) -> [EKEvent] {
        events.filter { calendar.isDate($0.startDate, inSameDayAs: day) }
    }
}
