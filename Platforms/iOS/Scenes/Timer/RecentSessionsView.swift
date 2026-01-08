#if os(iOS)
import SwiftUI

struct RecentSessionsView: View {
    @ObservedObject var viewModel: TimerPageViewModel
    @State private var editingSession: FocusSession?
    @State private var sessionToDelete: FocusSession?
    @State private var showDeleteConfirm = false
    @State private var selectedActivityFilter: UUID?
    @State private var showingFilters = false
    @State private var selectedDateRange: DateRange = .all
    @Environment(\.dismiss) private var dismiss
    
    enum DateRange: String, CaseIterable, Identifiable {
        case all = "All Time"
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Statistics header
                if !filteredSessions.isEmpty {
                    statisticsHeader
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                }
                
                // Sessions list
                List {
                    ForEach(sortedSectionDates, id: \.self) { date in
                        Section(header: Text(sectionTitle(for: date))) {
                            ForEach(groupedSessions[date] ?? []) { session in
                                SessionRow(
                                    session: session,
                                    activityName: activityName(for: session),
                                    onEdit: { editingSession = session },
                                    onDelete: {
                                        sessionToDelete = session
                                        showDeleteConfirm = true
                                    },
                                    onTap: { /* Could add detail view later */ }
                                )
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Recent Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("recentsessions.button.done", value: "Done", comment: "Done")) { dismiss() }
                }
            }
            .sheet(item: $editingSession) { session in
                EditSessionSheet(session: session, viewModel: viewModel)
            }
            .sheet(isPresented: $showingFilters) {
                filtersSheet
            }
            .alert("Delete Session?", isPresented: $showDeleteConfirm) {
                Button(NSLocalizedString("Cancel", value: "Cancel", comment: ""), role: .cancel) {
                    sessionToDelete = nil
                }
                Button(NSLocalizedString("Delete", value: "Delete", comment: ""), role: .destructive) {
                    if let session = sessionToDelete {
                        viewModel.deleteSessions(ids: [session.id])
                    }
                    sessionToDelete = nil
                }
            } message: {
                Text(NSLocalizedString("recentsessions.this.cant.be.undone", value: "This can't be undone.", comment: "This can't be undone."))
            }
        }
    }
    
    // MARK: - Statistics Header
    
    private var statisticsHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                statisticCard(
                    title: "Total",
                    value: "\(filteredSessions.count)",
                    icon: "clock"
                )
                
                statisticCard(
                    title: "Duration",
                    value: totalDurationString,
                    icon: "timer"
                )
                
                statisticCard(
                    title: "Average",
                    value: averageDurationString,
                    icon: "chart.bar"
                )
            }
        }
    }
    
    private func statisticCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.headline.monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
        )
    }
    
    // MARK: - Filters Sheet
    
    private var filtersSheet: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    Picker("Range", selection: $selectedDateRange) {
                        ForEach(DateRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Activity") {
                    Button {
                        selectedActivityFilter = nil
                    } label: {
                        HStack {
                            Text(NSLocalizedString("recentsessions.all.activities", value: "All Activities", comment: "All Activities"))
                            Spacer()
                            if selectedActivityFilter == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    
                    ForEach(viewModel.activities) { activity in
                        Button {
                            selectedActivityFilter = activity.id
                        } label: {
                            HStack {
                                if let emoji = activity.emoji {
                                    Text(emoji)
                                }
                                Text(activity.name)
                                Spacer()
                                if selectedActivityFilter == activity.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                if selectedActivityFilter != nil || selectedDateRange != .all {
                    Section {
                        Button(NSLocalizedString("recentsessions.button.clear.filters", value: "Clear Filters", comment: "Clear Filters")) {
                            selectedActivityFilter = nil
                            selectedDateRange = .all
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("recentsessions.button.done", value: "Done", comment: "Done")) {
                        showingFilters = false
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredSessions: [FocusSession] {
        var sessions = viewModel.pastSessions
        
        // Filter by activity
        if let activityID = selectedActivityFilter {
            sessions = sessions.filter { $0.activityID == activityID }
        }
        
        // Filter by date range
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedDateRange {
        case .all:
            break
        case .today:
            sessions = sessions.filter { session in
                guard let date = session.startedAt ?? session.endedAt else { return false }
                return calendar.isDateInToday(date)
            }
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            sessions = sessions.filter { session in
                guard let date = session.startedAt ?? session.endedAt else { return false }
                return date >= weekAgo
            }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            sessions = sessions.filter { session in
                guard let date = session.startedAt ?? session.endedAt else { return false }
                return date >= monthAgo
            }
        }
        
        return sessions
    }
    
    private var totalDuration: TimeInterval {
        filteredSessions.reduce(0) { total, session in
            let duration = session.actualDuration
                ?? session.plannedDuration
                ?? (session.endedAt.flatMap { end in session.startedAt.map { end.timeIntervalSince($0) } } ?? 0)
            return total + duration
        }
    }
    
    private var totalDurationString: String {
        formatDuration(totalDuration)
    }
    
    private var averageDurationString: String {
        guard !filteredSessions.isEmpty else { return "0m" }
        return formatDuration(totalDuration / Double(filteredSessions.count))
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let total = max(Int(duration.rounded()), 0)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private var groupedSessions: [Date: [FocusSession]] {
        let calendar = Calendar.current
        return Dictionary(grouping: filteredSessions) { session in
            let date = session.startedAt ?? session.endedAt ?? Date()
            return calendar.startOfDay(for: date)
        }
    }

    private var sortedSectionDates: [Date] {
        groupedSessions.keys.sorted(by: >)
    }

    private func sectionTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return dateFormatter.string(from: date)
        }
    }

    private func activityName(for session: FocusSession) -> String {
        guard let id = session.activityID,
              let activity = viewModel.activities.first(where: { $0.id == id }) else {
            return "None"
        }
        return activity.name
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

private struct SessionRow: View {
    let session: FocusSession
    let activityName: String
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: session.mode.systemImage)
                                .foregroundColor(.accentColor)
                            Text(session.mode.displayName)
                                .font(.headline)
                            Spacer()
                            Text(durationString)
                                .font(.subheadline.monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 8) {
                            Text(activityName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if session.state == .completed {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .accessibilityHidden(true)
                            }
                        }
                        
                        if let startedAt = session.startedAt {
                            Text(timeFormatter.string(from: startedAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Menu {
                        Button {
                            onEdit()
                        } label: {
                            Label(NSLocalizedString("recentsessions.label.edit", value: "Edit", comment: "Edit"), systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label(NSLocalizedString("recentsessions.label.delete", value: "Delete", comment: "Delete"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var durationString: String {
        let duration = session.actualDuration
            ?? session.plannedDuration
            ?? (session.endedAt.flatMap { end in session.startedAt.map { end.timeIntervalSince($0) } } ?? 0)
        let total = max(Int(duration.rounded()), 0)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
}
#endif
