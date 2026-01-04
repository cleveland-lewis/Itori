#if os(macOS)
import SwiftUI
import EventKit

struct CalendarGrid: View {
    @Binding var currentMonth: Date
    let events: [EKEvent]
    
    @EnvironmentObject private var eventsStore: EventsCountStore
    @EnvironmentObject private var calendarManager: CalendarManager
    @Environment(\.colorScheme) private var colorScheme
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var days: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        let monthStart = calendar.startOfDay(for: monthInterval.start)
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: monthStart)) else { return [] }
        
        let lastOfMonth = calendar.date(byAdding: .second, value: -1, to: monthInterval.end) ?? monthInterval.end
        guard let endOfWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastOfMonth)),
              let endOfWeek = calendar.date(byAdding: .day, value: 7, to: endOfWeekStart) else { return [] }
        
        var result: [Date?] = []
        var current = startOfWeek
        
        while current < endOfWeek && result.count < 42 {
            let day = calendar.startOfDay(for: current)
            let isInMonth = calendar.isDate(day, equalTo: currentMonth, toGranularity: .month)
            result.append(isInMonth ? day : nil)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 16) {
            weekdayHeader
            
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day = day {
                        GridDayCell(
                            day: day,
                            events: events(for: day),
                            isToday: calendar.isDateInToday(day),
                            isSelected: calendarManager.selectedDate.map { calendar.isDate(day, inSameDayAs: $0) } ?? false
                        )
                        .onTapGesture {
                            calendarManager.selectedDate = day
                        }
                    } else {
                        Color.clear
                            .frame(height: 80)
                    }
                }
            }
        }
    }
    
    private var weekdayHeader: some View {
        let symbols = calendar.shortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        let ordered = Array(symbols[first..<symbols.count] + symbols[0..<first])
        
        return HStack(spacing: 0) {
            ForEach(ordered, id: \.self) { symbol in
                Text(symbol.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func events(for day: Date) -> [EKEvent] {
        events.filter { calendar.isDate($0.startDate, inSameDayAs: day) }
            .sorted { $0.startDate < $1.startDate }
    }
}

private struct GridDayCell: View {
    let day: Date
    let events: [EKEvent]
    let isToday: Bool
    let isSelected: Bool
    
    @EnvironmentObject private var eventsStore: EventsCountStore
    @State private var isHovered = false
    
    private let calendar = Calendar.current
    
    private var dayNumber: Int {
        calendar.component(.day, from: day)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Day number at top-left with only today getting a red circle
            HStack {
                Text("\(dayNumber)")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(
                        isToday ? .white :
                        .primary
                    )
                    .padding(6)
                    .background(
                        // ONLY today gets a circle - small red circle
                        Group {
                            if isToday {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 22, height: 22)
                            }
                        }
                    )
                
                Spacer()
            }
            .padding(.top, 6)
            .padding(.leading, 6)
            
            // Event bars (horizontal colored bars, not dots)
            VStack(spacing: 2) {
                ForEach(events.prefix(3), id: \.eventIdentifier) { event in
                    EventBar(event: event)
                }
                
                if events.count > 3 {
                    Text("+\(events.count - 3)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: 90)  // Closer to square aspect ratio
        .background(
            // Selection highlights entire cell background
            Group {
                if isSelected {
                    Color.accentColor.opacity(0.15)
                }
            }
        )
        .background(DesignSystem.Materials.surface)
        .border(Color.primary.opacity(colorScheme == .dark ? 0.15 : 0.1), width: 0.5)  // Hairline border
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .overlay(
            // Subtle hover effect
            Group {
                if isHovered && !isSelected {
                    Color.primary.opacity(0.03)
                }
            }
        )
    }
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Helper view for event bars
    private struct EventBar: View {
        let event: EKEvent
        
        var body: some View {
            HStack(spacing: 3) {
                // Time for timed events
                if !event.isAllDay {
                    Text(timeString)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                // Colored bar with event title
                HStack(spacing: 0) {
                    // Color indicator bar
                    Rectangle()
                        .fill(categoryColor)
                        .frame(width: 2)
                    
                    Text(event.title)
                        .font(.system(size: 10))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.leading, 3)
                }
                .frame(height: 14)
                .background(categoryColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 2))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        private var timeString: String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: event.startDate)
        }
        
        private var categoryColor: Color {
            if let category = parseEventCategory(from: event.title) {
                return category.color
            }
            return .accentColor
        }
    }
}

struct CalendarHeader: View {
    @Binding var viewMode: CalendarViewMode
    @Binding var currentMonth: Date
    var onPrevious: () -> Void
    var onNext: () -> Void
    var onToday: () -> Void
    var onSearch: ((String) -> Void)?

    @State private var searchText: String = ""
    @EnvironmentObject private var settings: AppSettingsModel
    
    var body: some View {
        HStack(spacing: 16) {
            // View mode picker
            Picker("View", selection: $viewMode) {
                ForEach(CalendarViewMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 240)
            
            Spacer()
            
            // Navigation controls
            HStack(spacing: 8) {
                Button(action: onPrevious) {
                    calendarHeaderButtonLabel(
                        title: NSLocalizedString("common.button.previous", comment: ""),
                        systemImage: "chevron.left"
                    )
                    .font(.body.weight(.medium))
                }
                .buttonStyle(.plain)
                .rootsStandardInteraction()
                
                Button(action: onToday) {
                    Text("Today")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                
                Button(action: onNext) {
                    calendarHeaderButtonLabel(
                        title: NSLocalizedString("common.button.next", comment: ""),
                        systemImage: "chevron.right"
                    )
                    .font(.body.weight(.medium))
                }
                .buttonStyle(.plain)
                .rootsStandardInteraction()
            }
        }
    }

    @ViewBuilder
    private func calendarHeaderButtonLabel(title: String, systemImage: String) -> some View {
        switch settings.tabBarMode {
        case .iconsOnly:
            Image(systemName: systemImage)
        case .textOnly:
            Text(title)
        case .iconsAndText:
            HStack(spacing: DesignSystem.Spacing.xsmall) {
                Image(systemName: systemImage)
                Text(title)
            }
        }
    }
}
#endif
