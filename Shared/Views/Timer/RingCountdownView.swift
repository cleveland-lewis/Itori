import SwiftUI

/// Ring-style countdown visualization with enhanced animations
/// Feature: Phase A - Dynamic Countdown Visuals + UI Enhancements
struct RingCountdownView: View {
    let totalDuration: TimeInterval
    let remainingDuration: TimeInterval
    let isRunning: Bool
    var theme: EnhancedTimerTheme?
    
    @Environment(\.colorScheme) var colorScheme
    @State private var scale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    
    private var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, remainingDuration / totalDuration))
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
    
    private var lineWidth: CGFloat {
        theme?.ringThickness.lineWidth ?? 20
    }
    
    var body: some View {
        ZStack {
            // Subtle glow for active timer
            if isRunning {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ringColor.opacity(glowOpacity * 0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 100,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 20)
            }
            
            // Background ring
            Circle()
                .stroke(
                    Color.secondary.opacity(colorScheme == .dark ? 0.2 : 0.1),
                    lineWidth: lineWidth
                )
            
            // Progress ring with enhanced animation
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(theme?.animationStyle.animation ?? .easeInOut(duration: 0.5), value: progress)
                .shadow(color: ringColor.opacity(0.3), radius: 4, x: 0, y: 2)
            
            // Time display with scale animation
            VStack(spacing: 8) {
                Text(formattedTime)
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(ringColor)
                    .scaleEffect(scale)
                    .accessibilityLabel("Time remaining: \(formattedTime)")
                
                if !isRunning {
                    Text("Paused")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                }
            }
        }
        .frame(width: 280, height: 280)
        .padding()
        .onChange(of: isRunning) { newValue in
            if newValue {
                // Subtle pulse when started
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.05
                    glowOpacity = 1.0
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.1)) {
                    scale = 1.0
                    glowOpacity = 0.5
                }
            } else {
                glowOpacity = 0.0
            }
        }
        .onChange(of: Int(remainingDuration)) { _ in
            // Pulse on each second in last 10 seconds
            if remainingDuration <= 10 && remainingDuration > 0 {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    scale = 1.05
                }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7).delay(0.1)) {
                    scale = 1.0
                }
                
                // Haptic on last 3 seconds
                if remainingDuration <= 3 {
                    HapticFeedbackManager.shared.timeWarning()
                }
            }
        }
    }
    
    private var ringColor: Color {
        // Use theme color if available
        if let theme = theme {
            if progress < 0.25 {
                return theme.accentColor ?? theme.primaryColor
            } else if progress < 0.5 {
                return theme.secondaryColor ?? theme.primaryColor
            } else {
                return theme.primaryColor
            }
        }
        
        // Default color scheme
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
#Preview("Running") {
    RingCountdownView(
        totalDuration: 25 * 60,
        remainingDuration: 15 * 60,
        isRunning: true
    )
}

#Preview("Paused") {
    RingCountdownView(
        totalDuration: 25 * 60,
        remainingDuration: 5 * 60,
        isRunning: false
    )
}

#Preview("Almost Done") {
    RingCountdownView(
        totalDuration: 25 * 60,
        remainingDuration: 2 * 60,
        isRunning: true
    )
}
#endif
