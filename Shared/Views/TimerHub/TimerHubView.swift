import SwiftUI

/// Timer Hub - History and analytics view
/// Feature: Phase A - Timer Hub
struct TimerHubView: View {
    @ObservedObject var viewModel: TimerPageViewModel
    @State private var selectedFilter: SessionFilter = .all
    @State private var selectedDateRange: DateRange = .week
    
    enum SessionFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case completed = "Completed"
        case cancelled = "Cancelled"
        
        var id: String { rawValue }
    }
    
    enum DateRange: String, CaseIterable, Identifiable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"
        
        var id: String { rawValue }
    }
    
    private var filteredSessions: [FocusSession] {
        viewModel.pastSessions
            .filter { session in
                // Filter by state
                switch selectedFilter {
                case .all:
                    return true
                case .completed:
                    return session.state == .completed
                case .cancelled:
                    return session.state == .cancelled
                }
            }
            .filter { session in
                // Filter by date
                guard let startDate = session.startedAt else { return false }
                let now = Date()
                
                switch selectedDateRange {
                case .today:
                    return Calendar.current.isDateInToday(startDate)
                case .week:
                    let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
                    return startDate >= weekAgo
                case .month:
                    let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!
                    return startDate >= monthAgo
                case .all:
                    return true
                }
            }
    }
    
    private var statistics: TimerStatistics {
        let completed = filteredSessions.filter { $0.state == .completed }
        let totalDuration = completed.compactMap { $0.actualDuration }.reduce(0, +)
        let avgDuration = completed.isEmpty ? 0 : totalDuration / Double(completed.count)
        let longest = completed.compactMap { $0.actualDuration }.max() ?? 0
        
        return TimerStatistics(
            totalSessions: filteredSessions.count,
            totalDuration: totalDuration,
            completedSessions: completed.count,
            averageSessionDuration: avgDuration,
            longestSession: longest,
            currentStreak: calculateStreak(),
            lastSessionDate: filteredSessions.first?.startedAt
        )
    }
    
    var body: some View {
        List {
            Section {
                TimerStatisticsView(statistics: statistics)
            }
            
            Section {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(SessionFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                
                Picker("Period", selection: $selectedDateRange) {
                    ForEach(DateRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section {
                if filteredSessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions",
                        systemImage: "clock",
                        description: Text("Start a timer to see your sessions here")
                    )
                } else {
                    ForEach(filteredSessions) { session in
                        SessionListRow(session: session, viewModel: viewModel)
                    }
                }
            } header: {
                Text("Sessions (\(filteredSessions.count))")
            }
        }
        .navigationTitle("Timer Hub")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func calculateStreak() -> Int {
        let completedByDate = viewModel.pastSessions
            .filter { $0.state == .completed }
            .compactMap { $0.startedAt }
            .map { Calendar.current.startOfDay(for: $0) }
        
        guard !completedByDate.isEmpty else { return 0 }
        
        let uniqueDates = Set(completedByDate).sorted(by: >)
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())
        
        for date in uniqueDates {
            if date == currentDate {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            } else if date < currentDate {
                break
            }
        }
        
        return streak
    }
}

/// Row for displaying a single session in the list
private struct SessionListRow: View {
    let session: FocusSession
    @ObservedObject var viewModel: TimerPageViewModel
    
    private var activity: TimerActivity? {
        guard let activityID = session.activityID else { return nil }
        return viewModel.activities.first { $0.id == activityID }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Mode icon
                Image(systemName: session.mode.systemImage)
                    .foregroundColor(.accentColor)
                
                // Activity name or mode
                Text(activity?.name ?? session.mode.displayName)
                    .font(.headline)
                
                Spacer()
                
                // State badge
                Text(session.state.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(session.state == .completed ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(session.state == .completed ? .green : .secondary)
            }
            
            HStack {
                if let startDate = session.startedAt {
                    Text(startDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(startDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let duration = session.actualDuration {
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(formatDuration(duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        TimerHubView(viewModel: TimerPageViewModel.shared)
    }
}
#endif
