import SwiftUI

/// Native macOS-style analog clock following Apple's design guidelines
/// Implements proper accessibility, dynamic type, and system integration
struct NativeAnalogClock: View {
    var diameter: CGFloat = 160
    var showDigitalTime: Bool = true
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    private var radius: CGFloat { diameter / 2 }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 : nil, paused: false)) { context in
            let date = context.date
            VStack(spacing: 12) {
                clockFace(date: date)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabelWithTooltip(accessibilityTimeLabel(for: date))
                    .accessibilityAddTraits(.updatesFrequently)

                if showDigitalTime {
                    digitalTimeDisplay(for: date)
                }
            }
        }
    }

    private func clockFace(date: Date) -> some View {
        let components = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)

        return ZStack {
            // Background circle with proper vibrancy
            Circle()
                .fill(.background.secondary)
                .overlay {
                    Circle()
                        .strokeBorder(.separator.opacity(0.5), lineWidth: 1)
                }

            // Hour markers - Only major hours
            hourMarkers

            // Hour numerals
            hourNumerals

            // Clock hands
            clockHands(hour: components.hour ?? 0,
                      minute: components.minute ?? 0,
                      second: components.second ?? 0,
                      nanosecond: components.nanosecond ?? 0)
        }
        .frame(width: diameter, height: diameter)
    }
    
    private var hourMarkers: some View {
        ZStack {
            ForEach(0..<12) { index in
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(.primary.opacity(0.5))
                    .frame(width: 3, height: radius * 0.12)
                    .offset(y: -radius * 0.88)
                    .rotationEffect(.degrees(Double(index) * 30))
            }
        }
    }
    
    private var hourNumerals: some View {
        ZStack {
            ForEach([12, 3, 6, 9], id: \.self) { hour in
                let angle = Double(hour) / 12.0 * 360.0 - 90.0
                let radian = angle * .pi / 180.0
                let distance = radius * 0.62  // Moved inward from 0.68 for more even spacing
                
                Text(formatHour(hour))
                    .font(.system(size: diameter * 0.1, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .position(
                        x: radius + cos(radian) * distance,
                        y: radius + sin(radian) * distance
                    )
            }
        }
    }
    
    private func clockHands(hour: Int, minute: Int, second: Int, nanosecond: Int) -> some View {
        let seconds = Double(second) + Double(nanosecond) / 1_000_000_000
        let minutes = Double(minute) + seconds / 60
        let hours = Double(hour % 12) + minutes / 60
        
        return ZStack {
            // Hour hand
            Capsule(style: .continuous)
                .fill(.primary)
                .frame(width: radius * 0.08, height: radius * 0.55)
                .offset(y: -radius * 0.275)
                .rotationEffect(.degrees(hours * 30))
                .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
            
            // Minute hand
            Capsule(style: .continuous)
                .fill(.primary.opacity(0.9))
                .frame(width: radius * 0.06, height: radius * 0.8)
                .offset(y: -radius * 0.4)
                .rotationEffect(.degrees(minutes * 6))
                .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
            
            // Second hand (with ultra-smooth animation)
            if !reduceMotion {
                Capsule(style: .continuous)
                    .fill(.red)
                    .frame(width: radius * 0.025, height: radius * 0.85)
                    .offset(y: -radius * 0.425)
                    .rotationEffect(.degrees(seconds * 6))
            }
            
            // Center dot
            Circle()
                .fill(.primary)
                .frame(width: radius * 0.15, height: radius * 0.15)
                .shadow(color: .black.opacity(0.15), radius: 2)
        }
    }
    
    private func digitalTimeDisplay(for date: Date) -> some View {
        Text(date, style: .time)
            .font(.system(.body, design: .rounded, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: hour)) ?? "\(hour)"
    }
    
    private func accessibilityTimeLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return "Current time: \(formatter.string(from: date))"
    }
}

// MARK: - Dashboard Integration

struct DashboardClockCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Time", systemImage: "clock")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 24) {
                NativeAnalogClock(diameter: 140, showDigitalTime: false)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(Date(), style: .time)
                        .font(.system(size: 36, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                    
                    Text(Date(), style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.background.secondary)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.separator.opacity(0.5), lineWidth: 1)
                }
        }
    }
}

#if !DISABLE_PREVIEWS
#Preview("Native Analog Clock") {
    VStack(spacing: 40) {
        NativeAnalogClock(diameter: 200, showDigitalTime: true)
        
        DashboardClockCard()
            .frame(width: 400)
    }
    .padding(40)
    .background(Color(nsColor: .windowBackgroundColor))
}
#endif
