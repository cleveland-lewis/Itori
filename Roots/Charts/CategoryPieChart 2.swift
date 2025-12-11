import SwiftUI
import Charts

struct CategoryPieChart: View {
    @State private var selectedRange: AnalyticsTimeRange
    private let analytics = AnalyticsService.shared

    init(initialRange: AnalyticsTimeRange = .today) {
        _selectedRange = State(initialValue: initialRange)
    }

    private var distribution: [(category: String, seconds: Double)] {
        analytics.getCategoryDistribution(range: selectedRange)
    }

    private var categoryColors: [String: Color] = [
        "Homework": .blue,
        "Reading": .green,
        "Project": .orange,
        "Exam Prep": .red,
        "Other": .gray
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Task Distribution")
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
                Chart(distribution, id: \.category) { slice in
                    SectorMark(
                        angle: .value("Time", slice.seconds),
                        innerRadius: .ratio(0.4),
                        angularInset: 1.0
                    )
                    .foregroundStyle(categoryColors[slice.category] ?? Color.accentColor)
                    .annotation(position: .overlay) {
                        Text(slice.category)
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                }
                .chartLegend(.visible)
            } else {
                Text("Charts require macOS 13+")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding(DesignSystem.Layout.padding.card)
        .glassCard(cornerRadius: 16)
    }
}
