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
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    
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
            
            LazyVGrid(columns: columns, spacing: 8) {
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
        
        return HStack(spacing: 8) {
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
        VStack(alignment: .leading, spacing: 6) {
            // Day number with distinct today vs selected styling
            Text("\(dayNumber)")
                .font(.subheadline.weight(isToday ? .bold : .medium))
                .foregroundStyle(
                    isSelected ? .white :
                    isToday ? .accentColor :
                    .primary
                )
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(
                            isSelected ? Color.accentColor :
                            isToday ? .accentQuaternary :
                            Color.clear
                        )
                )
            
            // Event indicators (max 3 visible)
            VStack(spacing: 2) {
                ForEach(events.prefix(3), id: \.eventIdentifier) { event in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(categoryColor(for: event))
                            .frame(width: 4, height: 4)
                        
                        Text(event.title)
                            .font(.caption2)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 14)  // Fixed height per event row
                }
                
                if events.count > 3 {
                    Text("+\(events.count - 3) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(height: 14)  // Match event row height
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)  // Prevent expansion
            .clipped()  // Clip any overflow
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: 80)  // Fixed height
        .background(DesignSystem.Materials.surface)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.4) : Color.primary.opacity(0.08), lineWidth: isSelected ? 2 : 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private func categoryColor(for event: EKEvent) -> Color {
        if let category = parseEventCategory(from: event.title) {
            return category.color
        }
        return .accentColor
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
