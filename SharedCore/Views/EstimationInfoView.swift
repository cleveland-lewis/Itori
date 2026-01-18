import SwiftUI

/// Displays estimation information with confidence indicator
public struct EstimationInfoView: View {
    let estimate: DurationEstimate
    let showDetails: Bool

    @State private var isExpanded = false

    public init(estimate: DurationEstimate, showDetails: Bool = false) {
        self.estimate = estimate
        self.showDetails = showDetails
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Confidence indicator
                confidenceIndicator

                // Duration display
                Text(verbatim: "\(estimate.estimatedMinutes) min")
                    .font(.headline)

                // Range
                Text(verbatim: "(\(estimate.minMinutes)-\(estimate.maxMinutes))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if showDetails {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.itariLiquid)
                }
            }

            if isExpanded && showDetails {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("Estimation Factors", value: "Estimation Factors", comment: ""))
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    ForEach(estimate.reasonCodes, id: \.self) { code in
                        HStack {
                            Circle()
                                .fill(.tertiary)
                                .frame(width: 4, height: 4)
                            Text(formatReasonCode(code))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }
        }
    }

    @ViewBuilder
    private var confidenceIndicator: some View {
        Circle()
            .fill(confidenceColor)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(confidenceColor.opacity(0.3), lineWidth: 2)
                    .scaleEffect(1.5)
            )
            .help("Confidence: \(Int(estimate.confidence * 100))%")
    }

    private var confidenceColor: Color {
        if estimate.confidence >= 0.8 {
            .green
        } else if estimate.confidence >= 0.6 {
            .yellow
        } else {
            .orange
        }
    }

    private func formatReasonCode(_ code: String) -> String {
        // Format reason codes for display
        if code.starts(with: "category=") {
            return "Category: \(code.replacingOccurrences(of: "category=", with: "").capitalized)"
        } else if code.starts(with: "courseType=") {
            return "Course Type: \(code.replacingOccurrences(of: "courseType=", with: "").capitalized)"
        } else if code.starts(with: "credits=") {
            return "Credits: \(code.replacingOccurrences(of: "credits=", with: ""))"
        } else if code.starts(with: "historySampleSize=") {
            return "Historical Data: \(code.replacingOccurrences(of: "historySampleSize=", with: "")) completions"
        } else if code == "heuristicOnly" {
            return "Based on category defaults (no history yet)"
        } else if code == "blendedEstimate" {
            return "Combined historical data + defaults"
        }
        return code
    }
}

#if DEBUG
    struct EstimationInfoView_Previews: PreviewProvider {
        static var previews: some View {
            VStack(spacing: 20) {
                EstimationInfoView(
                    estimate: DurationEstimate(
                        estimatedMinutes: 90,
                        minMinutes: 72,
                        maxMinutes: 108,
                        confidence: 0.85,
                        reasonCodes: ["category=homework", "courseType=lab", "historySampleSize=5"]
                    ),
                    showDetails: true
                )

                EstimationInfoView(
                    estimate: DurationEstimate(
                        estimatedMinutes: 45,
                        minMinutes: 36,
                        maxMinutes: 54,
                        confidence: 0.5,
                        reasonCodes: ["category=reading", "heuristicOnly"]
                    ),
                    showDetails: true
                )
            }
            .padding()
        }
    }
#endif
