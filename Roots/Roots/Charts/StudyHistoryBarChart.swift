import SwiftUI
import Charts

struct StudyHistoryBarChart: View {
    @State private var selectedRange: AnalyticsTimeRange
    private let analytics = AnalyticsService.shared
    private let calendar = Calendar.current

    init(initialRange: AnalyticsTimeRange = .today) {
        _selectedRange = State(initialValue: initialRange)
    }

    private var trends: [(date: Date, seconds: Double)] {
        analytics.getStudyTrends(range: selectedRange)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Study Trends")
                    .font(DesignSystem.Typography.subHeader)
                Spacer()
                Picker("Range", selection: $selectedRange) {
                    ForEach(AnalyticsTimeRange.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 160)
            }

            if #available(macOS 13.0, *) {
                Chart(trends, id: \.date) { point in
                    BarMark(
                        x: .value("Date", formattedDate(point.date)),
                        y: .value("Hours", point.seconds / 3600)
                    )
                }
                .chartYAxisLabel("Hours Studied")
            } else {
                Text("Charts require macOS 13+")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding(DesignSystem.Layout.padding.card)
        .glassCard(cornerRadius: 16)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch selectedRange {
        case .today:
            formatter.dateFormat = "ha"
        case .thisWeek, .last7Days, .thisMonth:
            formatter.dateFormat = "MMM d"
        case .thisYear, .allTime:
            formatter.dateFormat = "MMM yyyy"
        }
        return formatter.string(from: date)
    }
}
