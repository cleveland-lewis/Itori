import SwiftUI

/// Statistics card view for Timer Hub
/// Feature: Phase A - Timer Hub
struct TimerStatisticsView: View {
    let statistics: TimerStatistics
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.accentColor)
                Text("Statistics")
                    .font(.headline)
                Spacer()
            }
            
            // Stats grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 16
            ) {
                StatCard(
                    title: "Total Sessions",
                    value: "\(statistics.totalSessions)",
                    icon: "timer"
                )
                
                StatCard(
                    title: "Completed",
                    value: "\(statistics.completedSessions)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Total Time",
                    value: formatDuration(statistics.totalDuration),
                    icon: "clock.fill"
                )
                
                StatCard(
                    title: "Current Streak",
                    value: "\(statistics.currentStreak) days",
                    icon: "flame.fill",
                    color: .orange
                )
            }
            
            // Additional stats
            if statistics.completedSessions > 0 {
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Average Session")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDuration(statistics.averageSessionDuration))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Longest Session")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDuration(statistics.longestSession))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(Int(duration))s"
        }
    }
}

/// Individual stat card
private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .accentColor
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

#if DEBUG
#Preview {
    TimerStatisticsView(
        statistics: TimerStatistics(
            totalSessions: 42,
            totalDuration: 1260 * 60,
            completedSessions: 38,
            averageSessionDuration: 25 * 60,
            longestSession: 90 * 60,
            currentStreak: 7,
            lastSessionDate: Date()
        )
    )
    .padding()
}
#endif
