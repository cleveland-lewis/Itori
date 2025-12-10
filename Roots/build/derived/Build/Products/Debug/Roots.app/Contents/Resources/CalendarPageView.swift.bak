import SwiftUI
import EventKit
import _Concurrency

enum CalendarViewMode: String, CaseIterable, Identifiable {
    case month, week
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

public struct CalendarEvent: Identifiable, Hashable {
    public let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var location: String?
    var notes: String?

    init(id: UUID = UUID(), title: String, startDate: Date, endDate: Date, location: String? = nil, notes: String? = nil) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
    }
}

struct CalendarPageView: View {
    @EnvironmentObject var settings: AppSettingsModel

    @EnvironmentObject var eventsStore: EventsCountStore
    @EnvironmentObject var calendarManager: CalendarManager
    @State private var currentViewMode: CalendarViewMode = .month
    @State private var focusedDate: Date = Date()
    @State private var selectedDate: Date? = Date()
    @State private var selectedEvent: CalendarEvent?
    @State private var metrics: CalendarStats = .empty
    @State private var showingNewEventSheet = false
    @State private var events: [CalendarEvent] = CalendarPageView.sampleEvents
    @State private var syncedEvents: [CalendarEvent] = []
    private let eventStore = EKEventStore()

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 14) {
            // Header + controls
            VStack(spacing: 8) {
                Text(monthTitle(for: focusedDate))
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)

                HStack(spacing: 10) {
                    RootsHeaderButton(icon: "chevron.left") { shift(by: -1) }
                        .rootsStandardInteraction()
                    RootsHeaderButton(icon: "chevron.right") { shift(by: 1) }
                        .rootsStandardInteraction()
                    RootsHeaderButton(icon: "plus") { showingNewEventSheet = true }
                        .rootsStandardInteraction()

                    Spacer()

                    Picker("View", selection: $currentViewMode) {
                        Text("Month").tag(CalendarViewMode.month)
                        Text("Week").tag(CalendarViewMode.week)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 420)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
            }

            // Metrics row
            MetricsRow(metrics: metrics)
                .padding(.horizontal, 12)

            // Main calendar content
            Group {
                switch currentViewMode {
                case .month:
                    MonthCalendarView(focusedDate: $focusedDate, events: effectiveEvents, onSelectDate: { day in
                        focusedDate = day
                        selectedDate = day
                        calendarManager.selectedDate = day
                        updateMetrics()
                    })
                case .week:
                    WeekCalendarView(focusedDate: $focusedDate, events: effectiveEvents)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassCard(cornerRadius: 22)
        }
        .padding(12)
        .sheet(isPresented: $showingNewEventSheet) {
            AddEventPopup().environmentObject(calendarManager)
        }
        .onAppear {
            requestAccessAndSync()
            calendarManager.refreshMonthlyCache(for: focusedDate)
            updateMetrics()
        }
        .onChange(of: focusedDate) { _, _ in
            calendarManager.refreshMonthlyCache(for: focusedDate)
            updateMetrics()
        }
        .onChange(of: currentViewMode) { _, _ in updateMetrics() }
        .onReceive(calendarManager.$cachedMonthEvents) { _ in
            updateMetrics()
        }
        // Present event detail without resizing layout
        .sheet(item: $selectedEvent, onDismiss: { selectedEvent = nil }) { event in
            EventDetailView(item: event, isPresented: Binding(get: { selectedEvent != nil }, set: { if !$0 { selectedEvent = nil } }))
        }
    }

    private func eventsFor(date: Date) -> [CalendarEvent] {
        let start = calendar.startOfDay(for: date)
        return effectiveEvents.filter { calendar.isDate($0.startDate, inSameDayAs: start) }
    }

    private func shift(by value: Int) {
        switch currentViewMode {
        case .month:
            if let newDate = calendar.date(byAdding: .month, value: value, to: focusedDate) {
                focusedDate = newDate
                selectedDate = newDate
            }
        case .week:
            if let newDate = calendar.date(byAdding: .weekOfYear, value: value, to: focusedDate) {
                focusedDate = newDate
                selectedDate = newDate
            }
        }
    }

    private func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }

    private var effectiveEvents: [CalendarEvent] {
        syncedEvents.isEmpty ? events : syncedEvents
    }

    private func requestAccessAndSync() {
        _Concurrency.Task {
            await calendarManager.requestAccess()
            // Only sync if access granted
            if calendarManager.eventAuthorizationStatus == .authorized || calendarManager.eventAuthorizationStatus == .fullAccess || calendarManager.reminderAuthorizationStatus == .authorized || calendarManager.reminderAuthorizationStatus == .fullAccess {
                syncEvents()
            } else {
                print("📅 [CalendarPageView] Access not granted; skipping sync")
            }
        }
    }

    private func syncEvents() {
        // Guard: don't attempt to read if not authorized
        if !(calendarManager.eventAuthorizationStatus == .authorized || calendarManager.eventAuthorizationStatus == .fullAccess || calendarManager.reminderAuthorizationStatus == .authorized || calendarManager.reminderAuthorizationStatus == .fullAccess) {
            print("📅 [CalendarPageView] syncEvents called without permissions")
            return
        }

        let window = visibleInterval()
        let predicate = eventStore.predicateForEvents(withStart: window.start, end: window.end, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        let mapped = ekEvents.map { ek in
            CalendarEvent(title: ek.title, startDate: ek.startDate, endDate: ek.endDate, location: ek.location, notes: ek.notes)
        }
        syncedEvents = mapped
        updateMetrics()
        // update precomputed counts
        let dates = mapped.map { calendar.startOfDay(for: $0.startDate) }
        _Concurrency.Task { @MainActor in
            eventsStore.update(dates: dates)
        }
        // Reminders (optional)
        let reminderPredicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: window.start, ending: window.end, calendars: nil)
        eventStore.fetchReminders(matching: reminderPredicate) { reminders in
            guard let reminders else { return }
            let mappedReminders = reminders.compactMap { reminder -> CalendarEvent? in
                guard let dueDate = reminder.dueDateComponents?.date else { return nil }
                return CalendarEvent(title: reminder.title, startDate: dueDate, endDate: dueDate, location: reminder.location, notes: reminder.notes)
            }
            DispatchQueue.main.async {
                self.syncedEvents.append(contentsOf: mappedReminders)
                // update counts with reminders too
                let dates = self.syncedEvents.map { calendar.startOfDay(for: $0.startDate) }
                _Concurrency.Task { @MainActor in
                    eventsStore.update(dates: dates)
                }
                updateMetrics()
            }
        }
    }

    private func formattedTimeRange(start: Date, end: Date) -> String {
        let use24 = AppSettingsModel.shared.use24HourTime
        let f = DateFormatter()
        f.dateFormat = use24 ? "HH:mm" : "h:mm a"
        return "\(f.string(from: start)) - \(f.string(from: end))"
    }

    private func events(on day: Date) -> [CalendarEvent] {
        let startOfDay = calendar.startOfDay(for: day)
        return effectiveEvents
            .filter { calendar.isDate($0.startDate, inSameDayAs: startOfDay) }
            .sorted { $0.startDate < $1.startDate }
    }

    private func visibleInterval() -> DateInterval {
        switch currentViewMode {
        case .month:
            if let interval = calendar.dateInterval(of: .month, for: focusedDate) {
                return interval
            }
        case .week:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: focusedDate)) ?? focusedDate
            let end = calendar.date(byAdding: .day, value: 7, to: start) ?? focusedDate
            return DateInterval(start: start, end: end)
        }
        return DateInterval(start: focusedDate, end: focusedDate.addingTimeInterval(24*3600))
    }

    private func updateMetrics() {
        metrics = CalendarStats.calculate(from: calendarManager.cachedMonthEvents, for: focusedDate)
    }
}

// MARK: - Month View

private struct MonthCalendarSplitView: View {
    @Binding var focusedDate: Date
    @Binding var selectedDate: Date?
    let events: [CalendarEvent]
    let onSelectDate: (Date) -> Void
    let onSelectEvent: (CalendarEvent) -> Void
    let timeFormatter: (Date, Date) -> String

    private let calendar = Calendar.current

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            MonthCalendarView(focusedDate: $focusedDate, events: events) { day in
                selectedDate = day
                onSelectDate(day)
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            VStack(alignment: .leading, spacing: 6) {
                Text("Selected Date")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                if let day = selectedDate {
                    Text(day.formatted(.dateTime.weekday().month().day()))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                } else {
                    Text("No date selected")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // Events list
            ScrollView {
                if let day = selectedDate {
                    let eventsForDay = events(on: day)
                    if eventsForDay.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.title2)
                                .foregroundStyle(.tertiary)
                            Text("No events")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(eventsForDay) { event in
                                Button {
                                    onSelectEvent(event)
                                } label: {
                                    EventRow(event: event)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(12)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("Select a day in the calendar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }
            }
        }
        .frame(minWidth: 260, maxWidth: 280)
        .glassCard(cornerRadius: 12)
    }

    private func events(on day: Date) -> [CalendarEvent] {
        events
            .filter { calendar.isDate($0.startDate, inSameDayAs: day) }
            .sorted { $0.startDate < $1.startDate }
    }
}

private struct MonthCalendarView: View {
    @Binding var focusedDate: Date
    let events: [CalendarEvent]
    let onSelectDate: (Date) -> Void
    @EnvironmentObject var eventsStore: EventsCountStore
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(monthHeader)
                    .font(.headline)
                weekdayHeader
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(days) { day in
                        let normalized = calendar.startOfDay(for: day.date)
                        let count = eventsStore.eventsByDate[normalized] ?? events(for: day.date).count
                        let isSelected = calendar.isDate(day.date, inSameDayAs: focusedDate)
                        let calendarDay = CalendarDay(
                            date: day.date,
                            isToday: calendar.isDateInToday(day.date),
                            isSelected: isSelected,
                            hasEvents: count > 0,
                            densityLevel: EventDensityLevel.fromCount(count),
                            isInCurrentMonth: day.isCurrentMonth
                        )
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                focusedDate = day.date
                            }
                            onSelectDate(day.date)
                        } label: {
                            MonthDayCell(day: calendarDay)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var monthHeader: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: focusedDate)
    }

    private var weekdayHeader: some View {
        let symbols = calendar.shortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        let ordered = Array(symbols[first..<symbols.count] + symbols[0..<first])
        return HStack(spacing: 6) {
            ForEach(ordered, id: \.self) { symbol in
                Text(symbol.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }


    private var days: [DayItem] {
        // Generate a safe, non-duplicating grid of days covering the month view
        guard let monthInterval = calendar.dateInterval(of: .month, for: focusedDate) else { return [] }
        let monthStart = calendar.startOfDay(for: monthInterval.start)
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: monthStart)) else { return [] }

        // last day of month is monthInterval.end - 1 second
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

        // Ensure full weeks
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

// MARK: - Week View

private struct WeekCalendarView: View {
    @Binding var focusedDate: Date
    let events: [CalendarEvent]
    @EnvironmentObject var settings: AppSettingsModel
    private let calendar = Calendar.current

    private struct PlaceholderBlock: Identifiable {
        let id = UUID()
        let dayIndex: Int
        let startHour: Double
        let duration: Double
        let title: String
    }

    private let placeholders: [PlaceholderBlock] = [
        .init(dayIndex: 1, startHour: 9, duration: 1.5, title: "Lecture"),
        .init(dayIndex: 3, startHour: 14, duration: 2, title: "Lab"),
        .init(dayIndex: 5, startHour: 19, duration: 1.5, title: "Study Block")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(weekTitle)
                .font(.headline)

            WeekHeaderView(weekDays: weekDays, focusedDate: $focusedDate, calendar: calendar, events: events)

            Divider().background(Color(nsColor: .separatorColor).opacity(0.12))

            ScrollView {
                ZStack(alignment: .topLeading) {
                    timeGrid
                    eventOverlay
                }
            }
        }
    }

    private var weekDays: [Date] {
        let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: focusedDate)) ?? focusedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private var weekTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        guard let start = weekDays.first,
              let end = calendar.date(byAdding: .day, value: 6, to: start) else {
            return formatter.string(from: focusedDate)
        }
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }

    private var timeGrid: some View {
        let hours = Array(6...23)
        return VStack(alignment: .leading, spacing: 22) {
            ForEach(hours, id: \.self) { hour in
                HStack(alignment: .top, spacing: 8) {
                    Text(formatHour(Double(hour)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor).opacity(0.08))
                        .frame(height: 1)
                }
            }
        }
        .padding(.bottom, 20)
    }

    private var eventOverlay: some View {
        GeometryReader { proxy in
            let width = proxy.size.width - 60
            let columnWidth = width / 7
            let hourHeight: CGFloat = 22

            VStack(alignment: .leading, spacing: 0) {
                ForEach(placeholders) { block in
                    let yOffset = CGFloat(block.startHour - 6) * hourHeight
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(settings.activeAccentColor.opacity(0.2))
                        .overlay(
                            VStack(alignment: .leading, spacing: 2) {
                                Text(block.title).font(.caption.weight(.semibold))
                                Text(formatHour(block.startHour)).font(.caption2).foregroundColor(.secondary)
                            }
                            .padding(8)
                        )
                        .frame(width: columnWidth - 8, height: CGFloat(block.duration) * hourHeight)
                        .offset(x: 60 + CGFloat(block.dayIndex) * columnWidth, y: yOffset)
                }
            }
        }
    }

    private func dayPill(for date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let day = calendar.component(.day, from: date)
        let weekdaySymbol = calendar.shortWeekdaySymbols[(calendar.component(.weekday, from: date) - 1 + 7) % 7]
        return VStack(spacing: 6) {
            Text(weekdaySymbol.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
            Text("\(day)")
                .font(.headline)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(isToday ? Color.accentColor.opacity(0.9) : Color(nsColor: .controlBackgroundColor).opacity(0.08))
                )
                .foregroundColor(isToday ? .white : .primary.opacity(0.8))
        }
        .padding(8)
        .glassChrome(cornerRadius: 14)
    }

    private func formatHour(_ hour: Double) -> String {
        let base = calendar.date(bySettingHour: Int(hour), minute: Int((hour.truncatingRemainder(dividingBy: 1)) * 60), second: 0, of: focusedDate) ?? focusedDate
        let formatter = DateFormatter()
        formatter.dateFormat = AppSettingsModel.shared.use24HourTime ? "HH:mm" : "h a"
        return formatter.string(from: base)
    }
}

// MARK: - Sidebar & Event Detail

private struct CalendarSidebarView: View {
    let selectedDate: Date
    let events: [CalendarEvent]
    let onSelectEvent: (CalendarEvent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            VStack(alignment: .leading, spacing: 6) {
                Text("Selected Date")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(selectedDate.formatted(.dateTime.weekday().month().day()))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // Events list
            ScrollView {
                if events.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("No events")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(events) { event in
                            Button {
                                onSelectEvent(event)
                            } label: {
                                EventRow(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                }
            }
        }
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
        )
    }
}

private struct EventRow: View {
    let event: CalendarEvent
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Text(timeRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let location = event.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovered ? Color(nsColor: .controlBackgroundColor).opacity(0.15) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: event.startDate)) – \(formatter.string(from: event.endDate))"
    }
}

private struct EventDetailView: View {
    let item: CalendarEvent
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(item.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Date and time
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    Text(dateRange)
                        .font(.body)
                        .foregroundStyle(.primary)
                }

                HStack(spacing: 10) {
                    Image(systemName: "clock")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    Text(timeRange)
                        .font(.body)
                        .foregroundStyle(.primary)
                }

                if let location = item.location, !location.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.body)
                            .foregroundStyle(.red)
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 24)
                        Text(location)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
            }

            if let notes = item.notes, !notes.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    ScrollView {
                        Text(notes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)
                }
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 420, minHeight: 320)
        .glassCard(cornerRadius: 16)
    }

    private var dateRange: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        return f.string(from: item.startDate)
    }

    private var timeRange: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return "\(f.string(from: item.startDate)) – \(f.string(from: item.endDate))"
    }
}

// MARK: - Event Chips

private struct EventChipsRow: View {
    var title: String
    var events: [CalendarEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            if events.isEmpty {
                Text("No events yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(events) { event in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.9))
                                    .frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.title)
                                        .font(.caption.weight(.semibold))
                                    Text(event.formattedTimeRange() + (event.location != nil ? " · \(event.location!)" : ""))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.06))
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Sample Data

private extension CalendarPageView {
    static var sampleEvents: [CalendarEvent] {
        let calendar = Calendar.current
        let now = Date()
        let laterToday = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        return [
            CalendarEvent(title: "CS Lecture", startDate: now, endDate: laterToday, location: "Hall A"),
            CalendarEvent(title: "Group Project Sync", startDate: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: now) ?? now, endDate: calendar.date(bySettingHour: 13, minute: 45, second: 0, of: now) ?? now, location: "Library"),
            CalendarEvent(title: "Math Problem Set", startDate: calendar.date(bySettingHour: 23, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 1, to: now) ?? now) ?? now, endDate: calendar.date(bySettingHour: 23, minute: 59, second: 0, of: calendar.date(byAdding: .day, value: 1, to: now) ?? now) ?? now, location: nil),
            CalendarEvent(title: "Lab Session", startDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 3, to: now) ?? now) ?? now, endDate: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 3, to: now) ?? now) ?? now, location: "Science Center")
        ]
    }
}

private extension CalendarEvent {
    func formattedTimeRange(use24HourTime: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = use24HourTime ? "HH:mm" : "h:mm a"
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }
}

// MARK: - Week Header View & Styles

private struct DayColumnStyle: ViewModifier {
    let cornerRadius: CGFloat = 14
    let height: CGFloat = 80
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .padding(8)
            .glassChrome(cornerRadius: cornerRadius)
    }
}

private extension View {
    func dayColumnStyle() -> some View { modifier(DayColumnStyle()) }
}

private struct WeekHeaderView: View {
    let weekDays: [Date]
    @Binding var focusedDate: Date
    let calendar: Calendar
    let events: [CalendarEvent]
    private let spacing: CGFloat = 8

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(weekDays, id: \.self) { date in
                let count = eventsCount(for: date)
                let day = CalendarDay(
                    date: date,
                    isToday: calendar.isDateInToday(date),
                    isSelected: calendar.isDate(date, inSameDayAs: focusedDate),
                    hasEvents: count > 0,
                    densityLevel: EventDensityLevel.fromCount(count),
                    isInCurrentMonth: true
                )
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        focusedDate = date
                    }
                } label: {
                    DayHeaderCard(day: day)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private func eventsCount(for date: Date) -> Int {
        let start = calendar.startOfDay(for: date)
        return events.filter { calendar.isDate($0.startDate, inSameDayAs: start) }.count
    }
}

// MARK: - Legacy compatibility wrapper

struct CalendarView: View {
    var body: some View {
        CalendarPageView()
    }
}

struct CalendarPageView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarPageView()
            .preferredColorScheme(.dark)
    }
}

private struct NewEventPlaceholder: View {
    var date: Date
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Event")
                .font(.title2.weight(.semibold))
            Text(date.formatted(date: .long, time: .omitted))
                .foregroundStyle(.secondary)
            Text("Event creation flow goes here.")
                .foregroundStyle(.secondary)
            Spacer()
            HStack {
                Spacer()
                Button("Close") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
    }
}

// MARK: - Shared Day Helpers

struct CalendarDay: Hashable {
    var date: Date
    var isToday: Bool
    var isSelected: Bool
    var hasEvents: Bool
    var densityLevel: EventDensityLevel
    var isInCurrentMonth: Bool
}

private struct DayHeaderCard: View {
    let day: CalendarDay
    private let calendar = Calendar.current
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 6) {
            Text(weekdaySymbol.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(day.isSelected ? .white : .secondary)
            Text("\(calendar.component(.day, from: day.date))")
                .font(.headline)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(day.isSelected ? Color.accentColor : Color.clear)
                        .background(
                            Circle().fill(DesignSystem.Materials.hud)
                        )
                )
                .foregroundColor(day.isSelected ? .white : .primary.opacity(0.8))
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .glassChrome(cornerRadius: 14)
        .scaleEffect(hovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: hovering)
        .onHover { hovering = $0 }
    }

    private var weekdaySymbol: String {
        Calendar.current.shortWeekdaySymbols[(Calendar.current.component(.weekday, from: day.date) - 1 + 7) % 7]
    }
}

private struct MonthDayCell: View {
    let day: CalendarDay
    private let calendar = Calendar.current
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 7) {
            Text(dayNumber)
                .font(.system(size: 13, weight: day.isSelected ? .bold : .semibold))
                .frame(width: 32, height: 32)
                .foregroundColor(textColor)
                .background(
                    Circle()
                        .fill(backgroundFill)
                        .background(
                            Circle().fill(DesignSystem.Materials.hud)
                        )
                        .shadow(color: day.isSelected ? Color.accentColor.opacity(0.25) : Color.clear, radius: 3, x: 0, y: 2)
                )
                .overlay(
                    Circle()
                        .strokeBorder(outlineColor, lineWidth: 1)
                )

        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .scaleEffect(hovering ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: hovering)
        .onHover { hovering = $0 }
    }

    private var dayNumber: String { String(calendar.component(.day, from: day.date)) }

    private var textColor: Color {
        if day.isSelected { return .white }
        if !day.isInCurrentMonth { return .secondary.opacity(0.5) }
        if day.isToday { return .accentColor }
        return .primary
    }

    private var backgroundFill: Color {
        if day.isSelected { return .accentColor }
        if day.isToday { return .accentColor.opacity(0.12) }
        return .clear
    }

    private var outlineColor: Color {
        day.isToday && !day.isSelected ? Color.accentColor.opacity(0.4) : .clear
    }
}

// MARK: - Metrics

private struct CalendarStats {
    let averagePerDay: Double
    let totalItems: Int
    let busiestDayName: String
    let busiestDayCount: Int

    static let empty = CalendarStats(averagePerDay: 0, totalItems: 0, busiestDayName: "—", busiestDayCount: 0)

    static func calculate(from events: [EKEvent], for date: Date) -> CalendarStats {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date) ?? 0..<0
        let numDaysInMonth = range.count

        let components = calendar.dateComponents([.year, .month], from: date)
        let monthEvents = events.filter { event in
            let eventComponents = calendar.dateComponents([.year, .month], from: event.startDate)
            return eventComponents.year == components.year && eventComponents.month == components.month
        }

        let total = monthEvents.count
        let average = numDaysInMonth > 0 ? Double(total) / Double(numDaysInMonth) : 0.0

        let eventsByDay = Dictionary(grouping: monthEvents) { event in
            calendar.component(.day, from: event.startDate)
        }

        if let maxEntry = eventsByDay.max(by: { $0.value.count < $1.value.count }) {
            var dayComponents = components
            dayComponents.day = maxEntry.key
            if let busyDate = calendar.date(from: dayComponents) {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return CalendarStats(
                    averagePerDay: average,
                    totalItems: total,
                    busiestDayName: formatter.string(from: busyDate),
                    busiestDayCount: maxEntry.value.count
                )
            }
        }

        return CalendarStats(
            averagePerDay: average,
            totalItems: total,
            busiestDayName: "—",
            busiestDayCount: 0
        )
    }
}

private struct MetricsRow: View {
    var metrics: CalendarStats
    private let columns = [GridItem(.adaptive(minimum: 180), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            MetricCard(title: "Average / Day", value: String(format: "%.1f", metrics.averagePerDay), subtitle: "This month", systemImage: "chart.bar.xaxis")
            MetricCard(title: "Total This Month", value: "\(metrics.totalItems)", subtitle: "Calendar items", systemImage: "calendar")
            MetricCard(title: "Busiest Day", value: metrics.busiestDayName, subtitle: busiestSubtitle, systemImage: "flame")
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.easeInOut, value: metrics.totalItems)
    }

    private var busiestSubtitle: String {
        metrics.busiestDayCount > 0 ? "\(metrics.busiestDayCount) items" : "No items"
    }
}

private struct MetricCard: View {
    var title: String
    var value: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(RootsColor.subtleFill))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .glassCard(cornerRadius: 14)
    }
}
