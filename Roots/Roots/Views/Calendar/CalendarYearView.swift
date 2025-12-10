import SwiftUI

struct CalendarYearView: View {
    var currentYear: Date
    private let calendar = Calendar.current

    private var months: [Date] {
        guard let yearInterval = calendar.dateInterval(of: .year, for: currentYear) else { return [] }
        return (0..<12).compactMap { calendar.date(byAdding: .month, value: $0, to: yearInterval.start) }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(months, id: \.self) { month in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(month.formatted(.dateTime.month(.wide)))
                            .font(.caption.bold())
                        MonthMiniGrid(month: month)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.08)))
                }
            }
            .padding()
        }
    }

    private struct MonthMiniGrid: View {
        let month: Date
        private let calendar = Calendar.current

        var body: some View {
            let days = makeDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(days, id: \.self) { day in
                    Text("\(calendar.component(.day, from: day))")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(calendar.isDate(day, equalTo: Date(), toGranularity: .day) ? Color.accentColor : .secondary)
                        .frame(maxWidth: .infinity, minHeight: 16, alignment: .topLeading)
                        .padding(2)
                }
            }
        }

        private func makeDays() -> [Date] {
            guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
            var start = calendar.date(from: calendar.dateComponents([.year, .month], from: monthInterval.start))!
            let weekday = calendar.component(.weekday, from: start)
            let delta = weekday - calendar.firstWeekday
            if delta > 0 { start = calendar.date(byAdding: .day, value: -delta, to: start)! }
            var days: [Date] = []
            for offset in 0..<42 {
                if let date = calendar.date(byAdding: .day, value: offset, to: start) { days.append(date) }
            }
            return days
        }
    }
}
