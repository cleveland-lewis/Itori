import SwiftUI
import EventKit
import Foundation
import _Concurrency

struct DashboardView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var calendarManager: CalendarManager
    @State private var isLoaded = false
    @State private var todayBounce = false
    @State private var energyBounce = false
    @State private var insightsBounce = false
    @State private var deadlinesBounce = false
    @State private var selectedDate: Date = Date()
    @State private var tasks: [DashboardTask] = [
        .init(title: "MA 231 – Problem Set 5", course: "MA 231", isDone: false),
        .init(title: "ST 311 – Quiz Review", course: "ST 311", isDone: false),
        .init(title: "Read Genetics notes", course: "GN 311", isDone: true)
    ]
    @State private var taskList: [Task] = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return [
            Task(title: "Finish lab report", dueDate: today, priority: .high),
            Task(title: "Read Chapter 5", dueDate: today, priority: .medium),
            Task(title: "Prep for quiz", dueDate: calendar.date(byAdding: .day, value: 1, to: today) ?? today, priority: .high),
            Task(title: "Start project outline", dueDate: calendar.date(byAdding: .day, value: 3, to: today) ?? today, priority: .low),
            Task(title: "Submit assignment", dueDate: calendar.date(byAdding: .day, value: -1, to: today) ?? today, priority: .medium)
        ]
    }()
    @State private var events: [DashboardEvent] = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return [
            .init(title: "MA 231 Lecture", time: "9:00–9:50 AM", location: "Biltmore 204", date: today),
            .init(title: "GN 311 Lab", time: "2:30–4:20 PM", location: "Jordan 112", date: calendar.date(byAdding: .day, value: 1, to: today) ?? today),
            .init(title: "Study Block – Library", time: "7:00–9:00 PM", location: "DHH Hill", date: calendar.date(byAdding: .day, value: 3, to: today) ?? today),
            .init(title: "Advisor Meeting", time: "3:00–3:45 PM", location: "Student Center", date: today)
        ]
    }()

    var body: some View {
        ScrollView {
            RootsDashboardGrid {
                RootsResponsiveGrid(statsItems) { item in
                    item.view
                        .frame(maxWidth: .infinity)
                        .animateEntry(isLoaded: isLoaded, index: item.index)
                }

                RootsCard {
                    VStack(alignment: .leading, spacing: RootsSpacing.m) {
                        Text("Calendar").rootsSectionHeader()
                        DashboardCalendarColumn(selectedDate: $selectedDate, events: events)
                    }
                }
                .animateEntry(isLoaded: isLoaded, index: 4)

                RootsCard {
                    VStack(alignment: .leading, spacing: RootsSpacing.m) {
                        Text("Upcoming Assignments").rootsSectionHeader()
                        DashboardTasksColumn(tasks: $tasks)
                    }
                }
                .animateEntry(isLoaded: isLoaded, index: 5)

                TaskDashboardCard(tasks: $taskList)
                    .animateEntry(isLoaded: isLoaded, index: 6)

                RootsCard {
                    VStack(alignment: .leading, spacing: RootsSpacing.m) {
                        Text("Events").rootsSectionHeader()
                        DashboardEventsColumn(events: events)
                    }
                }
                .animateEntry(isLoaded: isLoaded, index: 7)

                quickActionsCard
                    .animateEntry(isLoaded: isLoaded, index: 8)
            }
        }
        .onAppear {
            isLoaded = true
            LOG_UI(.info, "Navigation", "Displayed DashboardView")
        }
        .background(DesignSystem.Colors.appBackground)
    }

    private var todayCard: some View {
        RootsCard(
            title: cardTitle("Today Overview"),
            icon: "sun.max"
        ) {
            VStack(alignment: .leading, spacing: RootsSpacing.m) {
                let eventStatus = EKEventStore.authorizationStatus(for: .event)
                switch eventStatus {
                case .notDetermined:
                    HStack {
                        Text("Connect Apple Calendar to show events")
                            .rootsBody()
                        Spacer()
                        Button("Connect Apple Calendar", action: {
                            print("🔘 [Dashboard] Connect button tapped")
                            _Concurrency.Task {
                                await calendarManager.requestAccess()
                            }
                        })
                        .buttonStyle(RootsLiquidButtonStyle())
                    }
                case .denied, .restricted:
                    HStack {
                        Text("Access Denied. Open Settings.")
                            .rootsBody()
                        Spacer()
                        Button("Open Settings") {
                            calendarManager.openSystemPrivacySettings()
                        }
                        .buttonStyle(RootsLiquidButtonStyle())
                    }
                default:
                    if calendarManager.dailyEvents.isEmpty {
                        Text("No events today")
                            .rootsBodySecondary()
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(calendarManager.dailyEvents, id: \.eventIdentifier) { event in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(event.title)
                                            .font(.system(size: 13, weight: .semibold))
                                        Text("\(event.startDate.formatted(date: .omitted, time: .shortened)) – \(event.endDate.formatted(date: .omitted, time: .shortened))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
        }
        .onTapGesture {
            todayBounce.toggle()
            print("[Dashboard] card tapped: todayOverview")
        }
        .help("Today Overview")
    }

    private var energyCard: some View {
        Group {
            if settings.showEnergyPanel {
                RootsCard(
                    title: cardTitle("Energy & Focus"),
                    icon: "heart.fill"
                ) {
                    DashboardTileBody(
                        rows: [
                            ("Streak", "4 days"),
                            ("Focus Window", "Next slot 2h")
                        ]
                    )
                }
                .onTapGesture {
                    energyBounce.toggle()
                    print("[Dashboard] card tapped: energyFocus")
                }
                .help("Energy & Focus")
            } else {
                EmptyView()
            }
        }
    }

    private var insightsCard: some View {
        RootsCard(
            title: cardTitle("Insights"),
            icon: "lightbulb.fill"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .rootsBody()
            }
        }
        .onTapGesture {
            insightsBounce.toggle()
            print("[Dashboard] card tapped: insights")
        }
        .help("Insights")
    }

    private var deadlinesCard: some View {
        RootsCard(
            title: cardTitle("Upcoming Deadlines"),
            icon: "clock.arrow.circlepath"
        ) {
            DashboardTileBody(
                rows: [
                    ("Next", "Assignment - due tomorrow"),
                    ("Following", "Quiz - Friday")
                ]
            )
        }
        .onTapGesture {
            deadlinesBounce.toggle()
            print("[Dashboard] card tapped: upcomingDeadlines")
        }
        .help("Upcoming Deadlines")
    }

    private func cardTitle(_ title: String) -> String? { title }

    private var statsItems: [StatsCardItem] {
        [
            StatsCardItem(index: 0, view: AnyView(todayCard)),
            StatsCardItem(index: 1, view: AnyView(energyCard)),
            StatsCardItem(index: 2, view: AnyView(insightsCard)),
            StatsCardItem(index: 3, view: AnyView(deadlinesCard))
        ]
    }

    private var quickActionsCard: some View {
        RootsCard(
            title: "Quick Actions",
            icon: "bolt.fill"
        ) {
            HStack(spacing: RootsSpacing.m) {
                Button {
                    print("[Dashboard] Quick action: Add Assignment")
                } label: {
                    Label("Add Assignment", systemImage: "plus.circle")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderedProminent)

                Button {
                    print("[Dashboard] Quick action: Add Event")
                } label: {
                    Label("Add Event", systemImage: "calendar.badge.plus")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.bordered)
            }
        }
    }

}

struct StatsCardItem: Identifiable {
    let id = UUID()
    let index: Int
    let view: AnyView
}

struct DashboardTileBody: View {
    let rows: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.0)
                        .rootsBodySecondary()
                    Text(row.1)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(RootsColor.textPrimary)
                }
            }
        }
    }
}

private extension View {
    func animateEntry(isLoaded: Bool, index: Int) -> some View {
        self
            .opacity(isLoaded ? 1 : 0)
            .offset(y: isLoaded ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.05), value: isLoaded)
    }
}

// MARK: - Models for dashboard layout

struct DashboardTask: Identifiable {
    let id = UUID()
    var title: String
    var course: String?
    var isDone: Bool
}

struct DashboardEvent: Identifiable {
    let id = UUID()
    var title: String
    var time: String
    var location: String?
    var date: Date
}

// MARK: - Columns

private struct DashboardCalendarColumn: View {
    @Binding var selectedDate: Date
    var events: [DashboardEvent]
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendar").rootsSectionHeader()
            Text(monthHeader(for: selectedDate)).rootsBodySecondary()

            LazyVGrid(columns: columns, spacing: 8) {
                       ForEach(dayItems) { item in
                         let day = item.date
                    let isInMonth = calendar.isDate(day, equalTo: selectedDate, toGranularity: .month)
                    let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                    let normalized = calendar.startOfDay(for: day)
                    let count = eventsByDate[normalized] ?? 0

                    Button {
                        selectedDate = day
                    } label: {
                        CalendarDayCell(
                            date: day,
                            isInCurrentMonth: isInMonth,
                            isSelected: isSelected,
                            eventCount: count,
                            calendar: calendar
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .rootsCardBackground(radius: 20)
        }
        .padding()
        .rootsCardBackground(radius: 22)
    }

    private var eventsByDate: [Date: Int] {
        Dictionary(grouping: events, by: { calendar.startOfDay(for: $0.date) })
            .mapValues { $0.count }
    }

    private struct DayItem: Identifiable, Hashable {
        let id = UUID()
        let date: Date
        let isCurrentMonth: Bool
    }

    private var dayItems: [DayItem] {
        days.map { DayItem(date: $0, isCurrentMonth: calendar.isDate($0, equalTo: selectedDate, toGranularity: .month)) }
    }

    private var days: [Date] {
        // Safe generator that yields unique start-of-day Dates covering the month grid
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) else { return [] }
        let monthStart = calendar.startOfDay(for: monthInterval.start)
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: monthStart)) else { return [] }

        let lastOfMonth = calendar.date(byAdding: .second, value: -1, to: monthInterval.end) ?? monthInterval.end
        guard let endOfWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastOfMonth)),
              let endOfWeek = calendar.date(byAdding: .day, value: 7, to: endOfWeekStart) else { return [] }

        var items: [Date] = []
        var seen = Set<Date>()
        var current = startOfWeek

        while current < endOfWeek && items.count < 42 {
            let s = calendar.startOfDay(for: current)
            if !seen.contains(s) {
                items.append(s)
                seen.insert(s)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        // ensure full week rows
        while items.count % 7 != 0 {
            if let last = items.last, let next = calendar.date(byAdding: .day, value: 1, to: last) {
                let s = calendar.startOfDay(for: next)
                if !seen.contains(s) {
                    items.append(s)
                    seen.insert(s)
                } else { break }
            } else { break }
        }

        return items
    }

    private func monthHeader(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
}

private struct DashboardTasksColumn: View {
    @Binding var tasks: [DashboardTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today’s Tasks")
                .rootsSectionHeader()

            if tasks.isEmpty {
                Text("No tasks scheduled.")
                    .rootsBodySecondary()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(tasks.indices, id: \.self) { index in
                            TaskRow(task: $tasks[index],
                                    showConnectorAbove: index != 0,
                                    showConnectorBelow: index != tasks.count - 1)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .rootsCardBackground(radius: 22)
    }
}

private struct DashboardEventsColumn: View {
    var events: [DashboardEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Events")
                .rootsSectionHeader()

            if events.isEmpty {
                Text("No upcoming events.")
                    .rootsBodySecondary()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(events) { event in
                            HStack(alignment: .top, spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.title)
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(event.time)
                                        .rootsBodySecondary()
                                    if let location = event.location {
                                        Text(location)
                                            .rootsCaption()
                                    }
                                }
                                Spacer()
                            }
                            .padding(10)
                            .rootsCardBackground(radius: 18)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Calendar Load Helpers


// MARK: - Task Row

private struct TaskRow: View {
    @Binding var task: DashboardTask
    var showConnectorAbove: Bool
    var showConnectorBelow: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                VStack {
                    if showConnectorAbove {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.35))
                            .frame(width: 2, height: 8)
                            .offset(y: -6)
                    }
                    Spacer()
                    if showConnectorBelow {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.35))
                            .frame(width: 2, height: 8)
                            .offset(y: 6)
                    }
                }

                Button {
                    task.isDone.toggle()
                } label: {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.6), lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(task.isDone ? Color.accentColor : Color.clear)
                        )
                        .frame(width: 22, height: 22)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(task.isDone ? 1.0 : 0.0)
                        )
                }
                .buttonStyle(.plain)
            }
            .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 13, weight: .semibold))
                    .strikethrough(task.isDone, color: .secondary)

                if let course = task.course {
                    Text(course)
                        .rootsCaption()
                }
            }

            Spacer()
        }
        .padding(10)
        .rootsCardBackground(radius: 18)
    }
}

// MARK: - Static Month Calendar

struct StaticMonthCalendarView: View {
    let currentDate: Date
    var events: [DashboardEvent] = []
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(spacing: 10) {
            weekdayHeader
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(leadingBlanks, id: \.self) { _ in
                    Text(" ")
                        .frame(maxWidth: .infinity, minHeight: 28)
                }
                ForEach(daysInMonth, id: \.self) { day in
                    let date = calendar.date(bySetting: .day, value: day, of: currentDate) ?? currentDate
                    let count = events.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
                    let isSelected = calendar.isDate(date, inSameDayAs: currentDate)
                    CalendarDayCell(date: date, isInCurrentMonth: calendar.isDate(date, equalTo: currentDate, toGranularity: .month), isSelected: isSelected, eventCount: count, calendar: calendar)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var weekdayHeader: some View {
        let symbols = calendar.shortWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1 // Calendar is 1-based
        let ordered = Array(symbols[firstWeekdayIndex..<symbols.count] + symbols[0..<firstWeekdayIndex])

        return HStack(spacing: 6) {
            ForEach(ordered, id: \.self) { symbol in
                Text(symbol.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayView(_ day: Int) -> some View {
        let isToday = day == todayDay && isCurrentMonth
        return Text("\(day)")
            .font(.caption.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 32)
            .padding(6)
            .background(
                Circle()
                    .fill(isToday ? Color.accentColor.opacity(0.85) : Color.clear)
                    .background(
                        Circle().fill(Color(nsColor: .controlBackgroundColor).opacity(isToday ? 0.12 : 0.06))
                    )
            )
            .foregroundColor(isToday ? .white : .primary.opacity(0.7))
    }

    private var todayDay: Int {
        calendar.component(.day, from: currentDate)
    }

    private var isCurrentMonth: Bool {
        let now = Date()
        return calendar.isDate(now, equalTo: currentDate, toGranularity: .month)
    }

    private var daysInMonth: [Int] {
        guard let range = calendar.range(of: .day, in: .month, for: currentDate) else { return [] }
        return Array(range)
    }

    private var leadingBlanks: [Int] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: currentDate),
            let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else { return [] }

        let adjusted = (firstWeekday - calendar.firstWeekday + 7) % 7
        return Array(0..<adjusted)
    }
}
