#if os(iOS)
import SwiftUI

struct AutoRescheduleHistoryView: View {
    @StateObject private var engine = AutoRescheduleEngine.shared
    @State private var showClearConfirmation = false
    @Environment(\.appLayout) private var appLayout
    
    var body: some View {
        Group {
            if engine.rescheduleHistory.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .toolbar {
            if !engine.rescheduleHistory.isEmpty {
                Button(NSLocalizedString("settings.planner.reschedule.history.clear", value: "Clear", comment: "Clear history button")) {
                    showClearConfirmation = true
                }
                .confirmationDialog(
                    NSLocalizedString("settings.planner.reschedule.history.clear.title", value: "Clear Reschedule History", comment: "Clear history title"),
                    isPresented: $showClearConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(NSLocalizedString("settings.planner.reschedule.history.clear.action", value: "Clear History", comment: "Clear history action"), role: .destructive) {
                        clearHistory()
                    }
                    Button(NSLocalizedString("common.cancel", comment: "Cancel"), role: .cancel) {}
                } message: {
                    Text(NSLocalizedString("settings.planner.reschedule.history.clear.message", value: "This will permanently delete all reschedule history. This cannot be undone.", comment: "Clear history message"))
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundColor(.secondary)
            
            Text(NSLocalizedString("settings.planner.reschedule.history.empty.title", value: "No Reschedule History", comment: "Reschedule history empty title"))
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(NSLocalizedString("settings.planner.reschedule.history.empty.body", value: "When tasks are automatically rescheduled, they'll appear here", comment: "Reschedule history empty body"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var historyList: some View {
        List {
            ForEach(groupedByDate, id: \.key) { date, operations in
                Section {
                    ForEach(operations) { operation in
                        HistoryRow(operation: operation)
                    }
                } header: {
                    Text(formatDate(date))
                        .textCase(nil)
                        .fontWeight(.semibold)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var groupedByDate: [(key: Date, value: [AutoRescheduleEngine.RescheduleOperation])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: engine.rescheduleHistory) { operation in
            calendar.startOfDay(for: operation.timestamp)
        }
        return grouped.sorted { $0.key > $1.key } // Most recent first
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return NSLocalizedString("common.today", value: "Today", comment: "Today")
        } else if calendar.isDateInYesterday(date) {
            return NSLocalizedString("common.yesterday", value: "Yesterday", comment: "Yesterday")
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    private func clearHistory() {
        engine.clearHistory()
    }
}

struct HistoryRow: View {
    let operation: AutoRescheduleEngine.RescheduleOperation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Icon with fill provides shape differentiation
                Image(systemName: strategyIcon)
                    .foregroundColor(strategyColor)
                    .font(.title3)
                    .accessibilityLabel(operation.strategy.displayName)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(operation.strategy.displayName)
                        .font(.headline)
                    
                    HStack(spacing: 4) {
                        Text(formatTime(operation.originalStart))
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .accessibilityHidden(true)
                        Text(formatTime(operation.newStart))
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(formatTime(operation.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !operation.pushedSessions.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle")
                        .font(.caption)
                    Text(String(format: NSLocalizedString("settings.planner.reschedule.history.pushed", value: "Pushed %d task(s)", comment: "Pushed tasks count"), operation.pushedSessions.count))
                        .font(.caption)
                }
                .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var strategyIcon: String {
        switch operation.strategy {
        case .sameDaySlot: return "checkmark.circle.fill"
        case .sameDayPushed: return "arrow.up.circle.fill"
        case .nextDay: return "calendar.circle.fill"
        case .overflow: return "exclamationmark.triangle.fill"
        }
    }
    
    private var strategyColor: Color {
        switch operation.strategy {
        case .sameDaySlot: return .green
        case .sameDayPushed: return .orange
        case .nextDay: return .blue
        case .overflow: return .red
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

#if !DISABLE_PREVIEWS
#Preview("Empty") {
    NavigationStack {
        AutoRescheduleHistoryView()
            .navigationTitle("Reschedule History")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("With History") {
    // Note: Preview data assignment removed (setter inaccessible in Release)
    // To test with data, use the app in Debug mode
    NavigationStack {
        AutoRescheduleHistoryView()
            .navigationTitle("Reschedule History")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
#endif
