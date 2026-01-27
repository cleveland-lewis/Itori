import SwiftUI

/// Dynamic countdown view that switches between ring and grid styles
/// Feature: Phase A - Dynamic Countdown Visuals
struct DynamicCountdownView: View {
    @ObservedObject var viewModel: TimerPageViewModel
    @AppStorage("Itori.Timer.VisualStyle") private var visualStyle: TimerVisualStyle = .ring
    
    private var totalDuration: TimeInterval {
        viewModel.currentSession?.plannedDuration ?? 0
    }
    
    private var remainingDuration: TimeInterval {
        viewModel.sessionRemaining
    }
    
    private var isRunning: Bool {
        viewModel.currentSession?.state == .running
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Style picker
            CountdownStylePicker(selectedStyle: $visualStyle)
                .padding(.horizontal)
            
            // Dynamic countdown display
            Group {
                switch visualStyle {
                case .ring:
                    RingCountdownView(
                        totalDuration: totalDuration,
                        remainingDuration: remainingDuration,
                        isRunning: isRunning
                    )
                    .transition(.opacity)
                    
                case .grid:
                    GridCountdownView(
                        totalDuration: totalDuration,
                        remainingDuration: remainingDuration,
                        isRunning: isRunning
                    )
                    .transition(.opacity)
                    
                case .digital, .analog:
                    // Fallback to digital for now
                    Text(formattedTime)
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: visualStyle)
        }
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
}

#if DEBUG
#Preview {
    DynamicCountdownView(viewModel: TimerPageViewModel.shared)
}
#endif
