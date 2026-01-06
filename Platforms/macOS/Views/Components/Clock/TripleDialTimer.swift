import SwiftUI

/// Triple dial timer display showing hours, minutes, and seconds in separate dials
struct TripleDialTimer: View {
    let totalSeconds: TimeInterval
    let accentColor: Color
    var dialSize: CGFloat = 112
    
    private var timeComponents: (hours: Int, minutes: Int, seconds: Int) {
        let total = Int(totalSeconds)
        let h = (total / 3600) % 12  // 12-hour format
        let m = (total / 60) % 60
        let s = total % 60
        return (h, m, s)
    }
    
    var body: some View {
        HStack(spacing: 28) {
            // Hours dial (far left) - 12 hour max
            SingleDial(
                value: timeComponents.hours,
                maxValue: 12,
                label: "Hours",
                accentColor: accentColor,
                dialSize: dialSize
            )
            
            // Minutes dial (center) - 60 minutes max
            SingleDial(
                value: timeComponents.minutes,
                maxValue: 60,
                label: "Minutes",
                accentColor: accentColor,
                dialSize: dialSize
            )
            
            // Seconds dial (far right) - 60 seconds max
            SingleDial(
                value: timeComponents.seconds,
                maxValue: 60,
                label: "Seconds",
                accentColor: accentColor,
                dialSize: dialSize
            )
        }
        .padding(.vertical, 16)
    }
}

/// Single circular dial showing a value out of max
private struct SingleDial: View {
    let value: Int
    let maxValue: Int
    let label: String
    let accentColor: Color
    let dialSize: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    
    private var progress: Double {
        guard maxValue > 0 else { return 0 }
        return Double(value) / Double(maxValue)
    }
    
    private var angle: Double {
        progress * 360.0
    }
    
    var body: some View {
        let tickOffset = -(dialSize / 2 - 8)
        let handLength = dialSize * 0.34

        VStack(spacing: 6) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 2)
                    .frame(width: dialSize, height: dialSize)
                
                // Progress arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        accentColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: dialSize, height: dialSize)
                    .rotationEffect(.degrees(-90))
                
                // Tick marks
                ForEach(0..<tickCount, id: \.self) { index in
                    let isMajor = index % majorTickInterval == 0
                    Capsule()
                        .fill(Color.primary.opacity(isMajor ? 0.4 : 0.2))
                        .frame(width: isMajor ? 1.5 : 1, height: isMajor ? 6 : 4)
                        .offset(y: tickOffset)
                        .rotationEffect(.degrees(Double(index) * tickAngle))
                }
                
                // Hand
                Capsule()
                    .fill(accentColor)
                    .frame(width: 2, height: handLength)
                    .offset(y: -(handLength / 2))
                    .rotationEffect(.degrees(angle))
                
                // Center dot
                Circle()
                    .fill(accentColor)
                    .frame(width: 6, height: 6)
            }
            
            Text(verbatim: "\(value)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)

            // Label
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
    }
    
    private var tickCount: Int {
        switch maxValue {
        case 12: return 12
        case 60: return 60
        default: return maxValue
        }
    }
    
    private var majorTickInterval: Int {
        switch maxValue {
        case 12: return 3  // Every 3 hours
        case 60: return 5  // Every 5 minutes/seconds
        default: return max(1, maxValue / 12)
        }
    }
    
    private var tickAngle: Double {
        360.0 / Double(tickCount)
    }
}

#if !DISABLE_PREVIEWS
struct TripleDialTimer_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            TripleDialTimer(totalSeconds: 0, accentColor: .blue)
            TripleDialTimer(totalSeconds: 3665, accentColor: .blue)  // 1:01:05
            TripleDialTimer(totalSeconds: 125, accentColor: .blue)   // 2:05
        }
        .padding()
        .frame(width: 400, height: 600)
    }
}
#endif
