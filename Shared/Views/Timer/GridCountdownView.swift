import SwiftUI

/// Grid-style countdown visualization with animated blocks
/// Feature: Phase A - Dynamic Countdown Visuals
struct GridCountdownView: View {
    let totalDuration: TimeInterval
    let remainingDuration: TimeInterval
    let isRunning: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    private let columns = 10
    private let rows = 6
    private var totalBlocks: Int { columns * rows }
    
    private var activeBlocks: Int {
        guard totalDuration > 0 else { return 0 }
        let progress = remainingDuration / totalDuration
        return Int(Double(totalBlocks) * progress)
    }
    
    private var formattedTime: String {
        let hours = Int(remainingDuration) / 3600
        let minutes = Int(remainingDuration) / 60 % 60
        let seconds = Int(remainingDuration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Time display
            Text(formattedTime)
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .accessibilityLabel("Time remaining: \(formattedTime)")
            
            // Grid visualization
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: columns),
                spacing: 4
            ) {
                ForEach(0..<totalBlocks, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(blockColor(for: index))
                        .frame(height: 24)
                        .animation(.easeInOut(duration: 0.3), value: activeBlocks)
                }
            }
            .frame(maxWidth: 320)
            
            if !isRunning {
                Text("Paused")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private func blockColor(for index: Int) -> Color {
        guard index < activeBlocks else {
            return Color.secondary.opacity(colorScheme == .dark ? 0.2 : 0.1)
        }
        
        let progress = Double(activeBlocks) / Double(totalBlocks)
        if progress > 0.5 {
            return .green
        } else if progress > 0.25 {
            return .orange
        } else {
            return .red
        }
    }
}

#if DEBUG
#Preview("Running - Full") {
    GridCountdownView(
        totalDuration: 25 * 60,
        remainingDuration: 25 * 60,
        isRunning: true
    )
}

#Preview("Running - Half") {
    GridCountdownView(
        totalDuration: 25 * 60,
        remainingDuration: 12 * 60,
        isRunning: true
    )
}

#Preview("Running - Almost Done") {
    GridCountdownView(
        totalDuration: 25 * 60,
        remainingDuration: 3 * 60,
        isRunning: true
    )
}

#Preview("Paused") {
    GridCountdownView(
        totalDuration: 25 * 60,
        remainingDuration: 10 * 60,
        isRunning: false
    )
}
#endif
