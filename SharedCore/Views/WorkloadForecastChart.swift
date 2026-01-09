import Charts
import SwiftUI

/// Displays weekly workload forecast as a stacked bar chart
@available(macOS 13.0, iOS 16.0, *)
public struct WorkloadForecastChart: View {
    let forecast: WorkloadForecast
    let highlightPeakWeek: Bool

    public init(forecast: WorkloadForecast, highlightPeakWeek: Bool = true) {
        self.forecast = forecast
        self.highlightPeakWeek = highlightPeakWeek
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(NSLocalizedString("Workload Forecast", value: "Workload Forecast", comment: ""))
                    .font(.headline)

                Spacer()

                Text(verbatim: "\(Int(forecast.totalHours))h total")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Chart
            Chart {
                ForEach(forecast.weeklyLoad, id: \.weekStart) { week in
                    ForEach(week.breakdown.sorted(by: { $0.key < $1.key }), id: \.key) { category, hours in
                        BarMark(
                            x: .value("Week", week.weekStart, unit: .weekOfYear),
                            y: .value("Hours", hours)
                        )
                        .foregroundStyle(by: .value("Category", category))
                        .opacity(isPeakWeek(week.weekStart) && highlightPeakWeek ? 1.0 : 0.7)
                    }
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(formatWeekLabel(date))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text(verbatim: "\(Int(hours))h")
                        }
                    }
                }
            }
            .chartLegend(position: .bottom, spacing: 8)

            // Peak week indicator
            if let peakWeek = forecast.peakWeek, highlightPeakWeek {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(verbatim: "Peak workload week: \(formatWeekLabel(peakWeek))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }

    private func isPeakWeek(_ date: Date) -> Bool {
        guard let peakWeek = forecast.peakWeek else { return false }
        return Calendar.current.isDate(date, equalTo: peakWeek, toGranularity: .weekOfYear)
    }

    private func formatWeekLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

/// Simpler text-based workload summary for iOS or smaller displays
public struct WorkloadForecastSummary: View {
    let forecast: WorkloadForecast

    public init(forecast: WorkloadForecast) {
        self.forecast = forecast
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("Workload Forecast", value: "Workload Forecast", comment: ""))
                    .font(.headline)
                Spacer()
                Text(verbatim: "\(Int(forecast.totalHours))h total")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ForEach(forecast.weeklyLoad.prefix(4), id: \.weekStart) { week in
                HStack {
                    Text(formatWeekRange(week.weekStart))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(verbatim: "\(Int(week.hours))h")
                        .font(.callout.bold())

                    if let peakWeek = forecast.peakWeek,
                       Calendar.current.isDate(week.weekStart, equalTo: peakWeek, toGranularity: .weekOfYear)
                    {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }

            if forecast.weeklyLoad.count > 4 {
                Text(verbatim: "+ \(forecast.weeklyLoad.count - 4) more weeks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }

    private func formatWeekRange(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: date)

        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: date) ?? date
        let end = formatter.string(from: endDate)

        return "\(start) - \(end)"
    }
}

#if DEBUG
    @available(macOS 13.0, iOS 16.0, *)
    struct WorkloadForecastChart_Previews: PreviewProvider {
        static var previews: some View {
            let sampleForecast = WorkloadForecast(
                weeklyLoad: [
                    WeekLoad(weekStart: Date(), hours: 15, breakdown: ["homework": 8, "reading": 5, "review": 2]),
                    WeekLoad(
                        weekStart: Date().addingTimeInterval(7 * 24 * 3600),
                        hours: 22,
                        breakdown: ["homework": 10, "reading": 7, "project": 5]
                    ),
                    WeekLoad(
                        weekStart: Date().addingTimeInterval(14 * 24 * 3600),
                        hours: 18,
                        breakdown: ["exam": 12, "review": 6]
                    ),
                    WeekLoad(
                        weekStart: Date().addingTimeInterval(21 * 24 * 3600),
                        hours: 12,
                        breakdown: ["homework": 7, "reading": 5]
                    )
                ],
                peakWeek: Date().addingTimeInterval(7 * 24 * 3600),
                totalHours: 67
            )

            VStack(spacing: 20) {
                WorkloadForecastChart(forecast: sampleForecast)
                WorkloadForecastSummary(forecast: sampleForecast)
            }
            .padding()
        }
    }
#endif
