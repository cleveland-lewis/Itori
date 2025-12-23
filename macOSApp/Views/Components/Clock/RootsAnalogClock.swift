import SwiftUI

/// Minimalist analog clock with concentric rings and cardinal ticks.
/// When timerSeconds is provided, displays that time (defaulting to 12:00:00 when 0).
/// Otherwise shows system time.
struct RootsAnalogClock: View {
    @Environment(\.colorScheme) private var colorScheme
    var diameter: CGFloat = 200
    var showSecondHand: Bool = true
    var accentColor: Color = .accentColor
    var timerSeconds: TimeInterval? = nil // Timer state in seconds; nil = show system time

    private var radius: CGFloat { diameter / 2 }

    var body: some View {
        if let timerSeconds = timerSeconds {
            // Timer mode: display timer/stopwatch time (defaults to 12:00:00 when 0)
            let (hours, minutes, seconds) = timeComponents(from: timerSeconds)
            clockBody(hours: hours, minutes: minutes, seconds: seconds)
        } else {
            // System time mode: animated real-time clock
            TimelineView(.animation) { timeline in
                let date = timeline.date
                let components = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
                let seconds = Double(components.second ?? 0) + Double(components.nanosecond ?? 0) / 1_000_000_000
                let minutes = Double(components.minute ?? 0) + seconds / 60
                let rawHours = Double(components.hour ?? 0)
                let hours = rawHours.truncatingRemainder(dividingBy: 12) + minutes / 60
                clockBody(hours: hours, minutes: minutes, seconds: seconds)
            }
        }
    }
    
    /// Converts timer seconds to clock components (hours on 12-hour face, minutes, seconds)
    /// Defaults to 12:00:00 when timerSeconds is 0 or very small
    private func timeComponents(from timerSeconds: TimeInterval) -> (hours: Double, minutes: Double, seconds: Double) {
        // Default to 12:00:00 when idle (0 seconds)
        guard timerSeconds >= 1.0 else {
            return (hours: 0.0, minutes: 0.0, seconds: 0.0)
        }
        
        let totalSeconds = Int(timerSeconds)
        let s = Double(totalSeconds % 60)
        let m = Double((totalSeconds / 60) % 60)
        let h = Double((totalSeconds / 3600) % 12)
        
        // Add fractional seconds for smooth animation
        let fractionalSeconds = timerSeconds - Double(totalSeconds)
        let seconds = s + fractionalSeconds
        let minutes = m + seconds / 60.0
        let hours = h + minutes / 60.0
        
        return (hours: hours, minutes: minutes, seconds: seconds)
    }

    @ViewBuilder
    private func clockBody(hours: Double, minutes: Double, seconds: Double) -> some View {
        ZStack {
            face
            ticks
            hands(hours: hours, minutes: minutes, seconds: seconds)
        }
        .frame(width: diameter, height: diameter)
    }

    private var face: some View {
        ZStack {
            Circle()
                .fill(.clear)
                .overlay(
                    Circle().stroke(DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.28), lineWidth: 1)
                )

            ForEach(1..<4) { idx in
                Circle()
                    .stroke(idx == 2 ? accentColor : DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.16), lineWidth: 1)
                    .frame(width: diameter * (1 - CGFloat(idx) * 0.15), height: diameter * (1 - CGFloat(idx) * 0.15))
            }
        }
    }

    private var ticks: some View {
        ZStack {
            // Cardinal ticks
            ForEach([0, 90, 180, 270], id: \.self) { angle in
                Capsule(style: .continuous)
                    .fill(DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.9))
                    .frame(width: 6, height: 18)
                    .offset(y: -radius + 14)
                    .rotationEffect(.degrees(Double(angle)))
            }

            // Subtle hour ticks
            ForEach(0..<12) { idx in
                Capsule(style: .continuous)
                    .fill(DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.5))
                    .frame(width: 3, height: 10)
                    .offset(y: -radius + 12)
                    .rotationEffect(.degrees(Double(idx) * 30))
            }
        }
    }

    private func hands(hours: Double, minutes: Double, seconds: Double) -> some View {
        ZStack {
            // Hour hand
            Capsule(style: .continuous)
                .fill(Color.primary)
                .frame(width: 8, height: radius * 0.5)
                .offset(y: -radius * 0.25)
                .rotationEffect(.degrees((hours / 12) * 360))

            // Minute hand
            Capsule(style: .continuous)
                .fill(Color.primary.opacity(0.9))
                .frame(width: 6, height: radius * 0.7)
                .offset(y: -radius * 0.35)
                .rotationEffect(.degrees((minutes / 60) * 360))

            if showSecondHand {
                Capsule(style: .continuous)
                    .fill(accentColor)
                    .frame(width: 2, height: radius * 0.85)
                    .offset(y: -radius * 0.42)
                    .rotationEffect(.degrees((seconds / 60) * 360))
            }

            Circle()
                .fill(Color.primary.opacity(0.9))
                .frame(width: 10, height: 10)
        }
    }
}
