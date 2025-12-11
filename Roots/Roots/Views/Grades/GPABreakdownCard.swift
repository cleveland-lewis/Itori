import SwiftUI

struct GPABreakdownCard: View {
    var currentGPA: Double
    var academicYearGPA: Double?
    var cumulativeGPA: Double?
    var isLoading: Bool = false
    var courseCount: Int = 0

    var body: some View {
        RootsCard {
            VStack(alignment: .leading, spacing: 20) {
                Text("GPA Breakdown")
                    .font(DesignSystem.Typography.header)

                Divider()

                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Loading grades…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if courseCount == 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No courses with grades yet.")
                            .font(.subheadline.weight(.semibold))
                        Text("Add a course or log a grade to see your GPA breakdown.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    GPARow(label: "Current Semester", value: formatted(currentGPA), color: .blue)
                    GPARow(label: "Academic Year", value: formatted(academicYearGPA ?? currentGPA), color: .purple)
                    GPARow(label: "Cumulative", value: formatted(cumulativeGPA ?? currentGPA), color: .green)
                }
            }
            .padding(DesignSystem.Layout.padding.card)
        }
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    struct GPARow: View {
        let label: String
        let value: String
        let color: Color

        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(DesignSystem.Typography.display)
                        .foregroundStyle(.primary)
                }
                Spacer()

                Circle()
                    .trim(from: 0, to: 0.8)
                    .stroke(color.opacity(0.3), lineWidth: 4)
                    .overlay(
                        Circle().trim(from: 0, to: 0.6)
                            .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
            }
            .padding(.vertical, 4)
        }
    }
}
