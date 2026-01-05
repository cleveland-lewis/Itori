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
                Button("Clear") {
                    showClearConfirmation = true
                }
                .confirmationDialog(
                    "Clear Reschedule History",
                    isPresented: $showClearConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Clear History", role: .destructive) {
                        clearHistory()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will permanently delete all reschedule history. This cannot be undone.")
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Reschedule History")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("When tasks are automatically rescheduled, they'll appear here")
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
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
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
                Image(systemName: strategyIcon)
                    .foregroundColor(strategyColor)
                    .font(.body)
                
                Text(operation.strategy.displayName)
                    .font(.headline)
                
                Spacer()
                
                Text(formatTime(operation.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(formatTime(operation.originalStart))
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(operation.newStart))
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                if !operation.pushedSessions.isEmpty {
                    Text("Pushed \(operation.pushedSessions.count) task(s)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var strategyIcon: String {
        switch operation.strategy {
        case .sameDaySlot: return "clock.arrow.circlepath"
        case .sameDayPushed: return "arrow.up.square.fill"
        case .nextDay: return "calendar.badge.clock"
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
