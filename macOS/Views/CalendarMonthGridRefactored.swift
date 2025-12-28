#if os(macOS)
import SwiftUI

// MARK: - Fixed-Size Month Calendar Grid

/// Month calendar grid with fixed cell dimensions and stable layout
private struct MonthCalendarView: View {
    @Binding var focusedDate: Date
    let events: [CalendarEvent]
    let onSelectDate: (Date) -> Void
    let onSelectEvent: (CalendarEvent) -> Void
    @EnvironmentObject var eventsStore: EventsCountStore
    
    private let calendar = Calendar.current
    
    // Fixed dimensions for visual stability
    private let cellWidth: CGFloat = 140
    private let cellHeight: CGFloat = 120
    private let gridSpacing: CGFloat = 12
    private let dayNumberHeight: CGFloat = 28
    
    // LazyVGrid with exactly 7 fixed-width columns
    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(cellWidth), spacing: gridSpacing), count: 7)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            weekdayHeader
            
            LazyVGrid(columns: columns, spacing: gridSpacing) {
                ForEach(days) { day in
                    MonthDayCell(
                        day: day,
                        events: events(for: day.date),
                        cellWidth: cellWidth,
                        cellHeight: cellHeight,
                        dayNumberHeight: dayNumberHeight,
                        onSelectDate: { onSelectDate(day.date) },
                        onSelectEvent: onSelectEvent
                    )
                }
            }
        }
    }
    
    private var weekdayHeader: some View {
        let symbols = calendar.shortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        let ordered = Array(symbols[first..<symbols.count] + symbols[0..<first])
        
        return HStack(spacing: gridSpacing) {
            ForEach(ordered, id: \.self) { symbol in
                Text(symbol.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(width: cellWidth)
            }
        }
    }
    
    private var days: [DayItem] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: focusedDate) else { return [] }
        let monthStart = calendar.startOfDay(for: monthInterval.start)
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: monthStart)) else { return [] }
        
        let lastOfMonth = calendar.date(byAdding: .second, value: -1, to: monthInterval.end) ?? monthInterval.end
        guard let endOfWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastOfMonth)),
              let endOfWeek = calendar.date(byAdding: .day, value: 7, to: endOfWeekStart) else { return [] }
        
        var items: [DayItem] = []
        var seen = Set<Date>()
        var current = startOfWeek
        
        while current < endOfWeek && items.count < 42 {
            let s = calendar.startOfDay(for: current)
            if !seen.contains(s) {
                let isCurrentMonth = calendar.isDate(s, equalTo: focusedDate, toGranularity: .month)
                items.append(dayItem(for: s, isCurrentMonth: isCurrentMonth))
                seen.insert(s)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        
        while items.count % 7 != 0 {
            if let last = items.last?.date, let next = calendar.date(byAdding: .day, value: 1, to: last) {
                let s = calendar.startOfDay(for: next)
                if !seen.contains(s) {
                    let isCurrentMonth = calendar.isDate(s, equalTo: focusedDate, toGranularity: .month)
                    items.append(dayItem(for: s, isCurrentMonth: isCurrentMonth))
                    seen.insert(s)
                } else { break }
            } else { break }
        }
        
        return items
    }
    
    private func dayItem(for date: Date, isCurrentMonth: Bool) -> DayItem {
        DayItem(id: UUID(), date: date, isCurrentMonth: isCurrentMonth, isToday: calendar.isDateInToday(date))
    }
    
    private func events(for date: Date) -> [CalendarEvent] {
        events.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
    }
    
    private struct DayItem: Hashable, Identifiable {
        let id: UUID
        let date: Date
        let isCurrentMonth: Bool
        let isToday: Bool
    }
}

// MARK: - Fixed-Size Month Day Cell

/// Month day cell with fixed dimensions and day number in top-trailing overlay
private struct MonthDayCell: View {
    let day: MonthCalendarView.DayItem
    let events: [CalendarEvent]
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    let dayNumberHeight: CGFloat
    let onSelectDate: () -> Void
    let onSelectEvent: (CalendarEvent) -> Void
    
    @EnvironmentObject var eventsStore: EventsCountStore
    @State private var hovering = false
    
    private let calendar = Calendar.current
    private let eventSpacing: CGFloat = 4
    private let cellPadding: CGFloat = 8
    
    // Reserve space for day number at top
    private var eventContentHeight: CGFloat {
        cellHeight - dayNumberHeight - (cellPadding * 2)
    }
    
    var body: some View {
        Button(action: onSelectDate) {
            ZStack(alignment: .topTrailing) {
                // Cell background
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(backgroundFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: borderWidth)
                    )
                
                // Event content (with reserved space at top)
                VStack(alignment: .leading, spacing: 0) {
                    // Reserve space for day number
                    Color.clear
                        .frame(height: dayNumberHeight)
                    
                    // Events list (clipped and scrollable if needed)
                    if !events.isEmpty {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: eventSpacing) {
                                ForEach(events.prefix(3)) { event in
                                    EventPill(event: event, onTap: { onSelectEvent(event) })
                                }
                                
                                if events.count > 3 {
                                    Text("+\(events.count - 3) more")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.top, 2)
                                }
                            }
                        }
                        .frame(height: eventContentHeight)
                        .clipped()
                    }
                }
                .padding(cellPadding)
                
                // Day number overlay (top-trailing, always visible)
                Text(dayNumber)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(dayNumberColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(dayNumberBackground)
                    )
                    .padding(6)
            }
        }
        .buttonStyle(.plain)
        .frame(width: cellWidth, height: cellHeight)
        .scaleEffect(hovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: hovering)
        .onHover { hovering = $0 }
    }
    
    private var dayNumber: String {
        String(calendar.component(.day, from: day.date))
    }
    
    private var isSelected: Bool {
        eventsStore.eventsByDate[calendar.startOfDay(for: day.date)] != nil
    }
    
    private var backgroundFill: Color {
        if day.isToday {
            return Color.accentColor.opacity(0.08)
        }
        if hovering {
            return Color(nsColor: .controlBackgroundColor).opacity(0.12)
        }
        return DesignSystem.Colors.cardBackground
    }
    
    private var borderColor: Color {
        if day.isToday {
            return Color.accentColor.opacity(0.3)
        }
        return Color(nsColor: .separatorColor).opacity(0.2)
    }
    
    private var borderWidth: CGFloat {
        day.isToday ? 1.5 : 0.5
    }
    
    private var dayNumberColor: Color {
        if day.isToday {
            return .white
        }
        if !day.isCurrentMonth {
            return .secondary.opacity(0.4)
        }
        return .primary
    }
    
    private var dayNumberBackground: Color {
        if day.isToday {
            return Color.accentColor
        }
        return .clear
    }
}

// MARK: - Event Pill

/// Compact event pill for month view cells
private struct EventPill: View {
    let event: CalendarEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Circle()
                    .fill(event.category.color)
                    .frame(width: 6, height: 6)
                
                Text(event.title)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(event.category.color.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }
}

#endif
