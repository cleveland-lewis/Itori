import SwiftUI
#if canImport(Charts)
import Charts
#endif

struct TimerGraphsView: View {
    enum GraphMode: String, CaseIterable, Identifiable { case live, history; var id: String { rawValue } }

    @Binding var mode: GraphMode
    let sessions: [FocusSession]
    let currentSession: FocusSession?
    let sessionElapsed: TimeInterval
    let sessionRemaining: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Graph Mode", selection: $mode) {
                ForEach(GraphMode.allCases) { m in
                    Text(m == .live ? "Live" : "History").tag(m)
                }
            }
            .pickerStyle(.segmented)

            switch mode {
            case .live:
                liveGraph
            case .history:
                historyGraph
            }
        }
        .padding(DesignSystem.Layout.padding.card)
        .background(DesignSystem.Materials.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var liveGraph: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let session = currentSession {
                ProgressView(value: liveProgress(for: session))
                    .progressViewStyle(.linear)
                HStack {
                    Text("Elapsed \(format(minutes: sessionElapsed / 60))")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if session.plannedDuration != nil {
                        Text("Remaining \(format(minutes: sessionRemaining / 60))")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int((liveProgress(for: session)) * 100))%")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.accentColor)
                    }
                }
            } else {
                Text("No active session")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var historyGraph: some View {
        VStack(alignment: .leading, spacing: 12) {
            #if canImport(Charts)
            TimerBarChart(
                data: historyDataPoints,
                minutesPerDot: 5,
                xLabelFormatter: { date in
                    let f = DateFormatter()
                    f.dateFormat = "E"
                    return f.string(from: date)
                }
            )
            .frame(height: 220)
            #else
            HStack(alignment: .bottom, spacing: DesignSystem.Layout.spacing.small) {
                ForEach(historyPoints) { point in
                    VStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentColor.opacity(0.8))
                            .frame(width: 16, height: CGFloat(point.minutes))
                        Text(point.label)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 28)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            #endif

            VStack(alignment: .leading, spacing: 4) {
                Text("Today: \(format(minutes: todayMinutes))")
                Text("This Week: \(format(minutes: weekMinutes))")
            }
            .font(DesignSystem.Typography.caption)
            .foregroundColor(.secondary)
        }
    }

    private func liveProgress(for session: FocusSession) -> Double {
        guard let planned = session.plannedDuration, planned > 0 else { return 0 }
        return min(max(sessionElapsed / planned, 0), 1)
    }

    private var historyPoints: [HistoryPoint] {
        let calendar = Calendar.current
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }
        return days.reversed().map { day in
            let total = sessions
                .filter { session in
                    guard let end = session.endedAt else { return false }
                    return calendar.isDate(end, inSameDayAs: day)
                }
                .reduce(0.0) { partial, session in
                    partial + (session.actualDuration ?? session.plannedDuration ?? 0)
                } / 60

            return HistoryPoint(date: day, minutes: total)
        }
    }

    private var historyDataPoints: [TimerDataPoint] {
        let calendar = Calendar.current
        return historyPoints.map { point in
            TimerDataPoint(
                date: point.date,
                minutes: point.minutes,
                isCurrent: calendar.isDateInToday(point.date)
            )
        }
    }

    private var todayMinutes: Double {
        let calendar = Calendar.current
        return sessions
            .filter { session in
                guard let end = session.endedAt else { return false }
                return calendar.isDateInToday(end)
            }
            .reduce(0.0) { partial, session in
                partial + (session.actualDuration ?? session.plannedDuration ?? 0)
            } / 60
    }

    private var weekMinutes: Double {
        let calendar = Calendar.current
        guard let start = calendar.date(byAdding: .day, value: -6, to: Date()) else { return 0 }
        return sessions
            .filter { session in
                guard let end = session.endedAt else { return false }
                return end >= start
            }
            .reduce(0.0) { partial, session in
                partial + (session.actualDuration ?? session.plannedDuration ?? 0)
            } / 60
    }

    private func format(minutes: Double) -> String {
        let totalSeconds = Int(minutes * 60)
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

private struct HistoryPoint: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Double

    var label: String {
        let f = DateFormatter()
        f.dateFormat = "E"
        return f.string(from: date)
    }
}

// Lightweight data model for dotted history chart
struct TimerDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Double
    let isCurrent: Bool
}

#if canImport(Charts)
import Charts

// Local dotted bar chart to avoid missing target membership issues.
struct TimerBarChart: View {
    let data: [TimerDataPoint]
    var minutesPerDot: Double = 5
    var xLabelFormatter: (Date) -> String = { date in
        let f = DateFormatter()
        f.dateFormat = "E"
        return f.string(from: date)
    }

    var body: some View {
        Chart {
            ForEach(data) { point in
                let dotCount = max(1, Int(ceil(point.minutes / minutesPerDot)))
                ForEach(0..<dotCount, id: \.self) { idx in
                    PointMark(
                        x: .value("Time", point.date),
                        y: .value("Minutes", Double(idx) * minutesPerDot)
                    )
                    .symbolSize(28)
                    .foregroundStyle(point.isCurrent ? Color.yellow : Color.secondary.opacity(0.55))
                }

                if point.isCurrent {
                    PointMark(
                        x: .value("Time", point.date),
                        y: .value("Minutes", max(point.minutes, minutesPerDot))
                    )
                    .symbol(.circle)
                    .symbolSize(120)
                }
            }
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: data.map(\.date)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(xLabelFormatter(date))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    AxisTick()
                }
            }
        }
        .frame(height: 220)
    }
}
#endif
