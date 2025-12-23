import SwiftUI

/// Minimalist analog clock with concentric rings and cardinal ticks.
/// When timerSeconds is provided, displays that time (defaulting to 12:00:00 when 0).
/// Otherwise shows system time.
struct RootsAnalogClock: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var diameter: CGFloat = 200
    var showSecondHand: Bool = true
    var accentColor: Color = .accentColor
    var timerSeconds: TimeInterval? = nil // Timer state in seconds; nil = show system time
    var showNumerals: Bool = true // Show hour numerals on clock face

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
            if showNumerals {
                numerals
            }
            // Minutes sub-dial (0-60)
            StopwatchSubDial(
                diameter: diameter * 0.32,
                value: minutes / 60.0,
                maxValue: 60,
                numerals: [15, 30, 45, 60],
                accentColor: accentColor,
                colorScheme: colorScheme
            )
            .offset(y: radius * 0.28)
            
            // Hours sub-dial (0-12)
            StopwatchSubDial(
                diameter: diameter * 0.26,
                value: hours / 12.0,
                maxValue: 12,
                numerals: [3, 6, 9, 12],
                accentColor: accentColor,
                colorScheme: colorScheme
            )
            .offset(y: -radius * 0.16)
            
            hands(hours: hours, minutes: minutes, seconds: seconds)
        }
        .frame(width: diameter, height: diameter)
    }

    private var face: some View {
        ZStack {
            Circle()
                .fill(.clear)
                .overlay(
                    Circle().stroke(DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.5), lineWidth: 2)
                )

            ForEach(1..<4) { idx in
                Circle()
                    .stroke(idx == 2 ? accentColor : DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.2), lineWidth: 1)
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
    
    private var numerals: some View {
        ZStack {
            // Display key numerals (12, 3, 6, 9) or all 12 hours
            ForEach(cardinalHours, id: \.self) { hour in
                let angle = (Double(hour) / 12.0) * 360.0 - 90.0
                let radian = angle * .pi / 180.0
                let numeralDistance = radius * 0.72
                
                Text(formatHour(hour))
                    .font(numeralFont)
                    .foregroundColor(Color.primary.opacity(0.85))
                    .position(
                        x: radius + numeralDistance * cos(radian),
                        y: radius + numeralDistance * sin(radian)
                    )
            }
        }
    }
    
    private var cardinalHours: [Int] {
        // Show cardinal hours (12, 3, 6, 9) for smaller clocks, all hours for larger
        diameter >= 250 ? Array(1...12) : [12, 3, 6, 9]
    }
    
    private var numeralFont: Font {
        let baseSize: CGFloat = diameter / 12
        let scaledSize = baseSize * dynamicTypeSizeMultiplier
        return .system(size: scaledSize, weight: .medium, design: .rounded)
    }
    
    private var dynamicTypeSizeMultiplier: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.1
        case .xLarge: return 1.2
        case .xxLarge: return 1.3
        case .xxxLarge: return 1.4
        default: return 1.5
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        // Use localized number format
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: hour)) ?? "\(hour)"
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

struct StopwatchSubDial: View {
    let diameter: CGFloat
    let value: Double
    let maxValue: Int
    let numerals: [Int]
    let accentColor: Color
    let colorScheme: ColorScheme
    
    private var radius: CGFloat { diameter / 2 }
    
    var body: some View {
        ZStack {
            // Dial face with ticks
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.18), lineWidth: 1)
                
                // Tick marks (60 total, major every 5)
                ForEach(0..<60) { idx in
                    let isMajor = idx % 5 == 0
                    Capsule(style: .continuous)
                        .fill(DesignSystem.Colors.neutralLine(for: colorScheme).opacity(isMajor ? 0.6 : 0.35))
                        .frame(width: isMajor ? 2.5 : 1.5, height: isMajor ? 8 : 5)
                        .offset(y: -radius + (isMajor ? 8 : 7))
                        .rotationEffect(.degrees(Double(idx) * 6))
                }
                
                // Numerals
                ForEach(numerals, id: \.self) { numeral in
                    let mapped = numeral == maxValue ? 0 : numeral
                    let angle = Double(mapped) / Double(maxValue) * 360.0 - 90.0
                    let radian = angle * .pi / 180.0
                    
                    Text("\(numeral)")
                        .font(.system(size: diameter * 0.12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary.opacity(0.65))
                        .frame(width: diameter * 0.28, height: diameter * 0.2, alignment: .center)
                        .position(
                            x: radius + cos(radian) * radius * 0.72,
                            y: radius + sin(radian) * radius * 0.72
                        )
                }
            }
            .drawingGroup()
            
            // Hand
            Capsule(style: .continuous)
                .fill(Color.primary.opacity(0.9))
                .frame(width: 2, height: radius * 0.7)
                .offset(y: -radius * 0.35)
                .rotationEffect(.degrees(value * 360))
            
            // Center dot
            Circle()
                .fill(accentColor.opacity(0.4))
                .frame(width: 5, height: 5)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(maxValue == 60 ? "Minutes" : "Hours") sub-dial")
    }
}
