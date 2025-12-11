import SwiftUI
import Charts

extension DesignSystem {
    enum Charts {
        struct Palettes {
            /// Categorical palettes that rely on dynamic/system colors so they adapt to Light/Dark automatically
            static let primary: [Color] = [Color.accentColor, .blue, .green, .orange, .purple]
            static let secondary: [Color] = [Color.secondary, Color.primary.opacity(0.8), Color.primary.opacity(0.5)]
        }

        // Axis helper presets to keep charts consistent with HIG
        struct AxisPresets {
            /// Standard 7-day X axis for small weekly overviews
            static var dailyXAxis: AxisMarks {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }

            /// Percentage Y axis intended for 0...100 domains
            static var percentageYAxis: AxisMarks {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .percent)
                }
            }

            /// Minimal axis for trend-only charts
            static var minimalAxis: AxisMarks {
                AxisMarks() { _ in
                    // Hide gridlines and labels for a clean trend display
                }
            }
        }

        // Small helpers for common styling
        struct Style {
            static func lineStyle(primary: Color) -> StrokeStyle { StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round) }
        }
    }
}
