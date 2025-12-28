#if os(macOS)
import SwiftUI

struct CalendarYearView: View {
    let currentYear: Date
    
    @EnvironmentObject private var eventsStore: EventsCountStore
    @Environment(\.colorScheme) private var colorScheme
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 24), count: 3)
    
    private var months: [Date] {
        let year = calendar.component(.year, from: currentYear)
        return (1...12).compactMap { month in
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            return calendar.date(from: components)
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 32) {
                ForEach(months, id: \.self) { month in
                    MiniMonthView(month: month)
                }
            }
            .padding(24)
        }
    }
}

private struct MiniMonthView: View {
    let month: Date
    
    @EnvironmentObject private var eventsStore: EventsCountStore
    @Environment(\.colorScheme) private var colorScheme
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: month)
    }
    
    private var days: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let monthStart = calendar.startOfDay(for: monthInterval.start)
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: monthStart)) else { return [] }
        
        let lastOfMonth = calendar.date(byAdding: .second, value: -1, to: monthInterval.end) ?? monthInterval.end
        guard let endOfWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastOfMonth)),
              let endOfWeek = calendar.date(byAdding: .day, value: 7, to: endOfWeekStart) else { return [] }
        
        var result: [Date?] = []
        var current = startOfWeek
        
        while current < endOfWeek && result.count < 42 {
            let day = calendar.startOfDay(for: current)
            let isInMonth = calendar.isDate(day, equalTo: month, toGranularity: .month)
            result.append(isInMonth ? day : nil)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(monthName)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            weekdayHeader
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day = day {
                        MiniDayCell(day: day)
                    } else {
                        Color.clear
                            .frame(height: 24)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(DesignSystem.Materials.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
    
    private var weekdayHeader: some View {
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        let ordered = Array(symbols[first..<symbols.count] + symbols[0..<first])
        
        return HStack(spacing: 4) {
            ForEach(ordered, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct MiniDayCell: View {
    let day: Date
    
    @EnvironmentObject private var eventsStore: EventsCountStore
    
    private let calendar = Calendar.current
    
    private var dayNumber: Int {
        calendar.component(.day, from: day)
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(day)
    }
    
    private var hasEvents: Bool {
        let normalized = calendar.startOfDay(for: day)
        return (eventsStore.eventsByDate[normalized] ?? 0) > 0
    }
    
    var body: some View {
        ZStack {
            if isToday {
                Circle()
                    .fill(Color.accentColor)
            }
            
            Text("\(dayNumber)")
                .font(.caption2)
                .foregroundStyle(isToday ? .white : .primary)
            
            if hasEvents && !isToday {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 3, height: 3)
                    .offset(y: 8)
            }
        }
        .frame(height: 24)
        .frame(maxWidth: .infinity)
    }
}
#endif
