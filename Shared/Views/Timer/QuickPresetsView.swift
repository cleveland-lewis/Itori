import SwiftUI

/// Quick access preset buttons for common timer durations
/// Feature: Phase A - Quick Timer Presets
struct QuickPresetsView: View {
    @ObservedObject var viewModel: TimerPageViewModel
    @Environment(\.colorScheme) var colorScheme
    
    let presets: [TimerPreset]
    
    init(viewModel: TimerPageViewModel, presets: [TimerPreset]? = nil) {
        self.viewModel = viewModel
        self.presets = presets ?? TimerPreset.defaults
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(presets.sorted(by: { $0.sortOrder < $1.sortOrder })) { preset in
                    PresetButton(preset: preset, viewModel: viewModel)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 80)
    }
}

/// Individual preset button
private struct PresetButton: View {
    let preset: TimerPreset
    @ObservedObject var viewModel: TimerPageViewModel
    @Environment(\.colorScheme) var colorScheme
    
    private var isActive: Bool {
        viewModel.currentSession != nil
    }
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            startPresetTimer()
        } label: {
            VStack(spacing: 4) {
                if let emoji = preset.emoji {
                    Text(emoji)
                        .font(.title2)
                }
                
                Text(preset.name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(formatDuration(preset.duration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, height: 64)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(presetColor.opacity(colorScheme == .dark ? 0.3 : 0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(presetColor.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: isPressed ? presetColor.opacity(0.3) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .disabled(isActive)
        .opacity(isActive ? 0.5 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed && !isActive {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isPressed = true
                        }
                        HapticFeedbackManager.shared.presetTapped()
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
        .accessibilityLabel("\(preset.name), \(formatDuration(preset.duration))")
        .accessibilityHint("Start timer with this preset duration")
    }
    
    private var presetColor: Color {
        if let colorHex = preset.colorHex, let color = Color(hex: colorHex) {
            return color
        }
        return .accentColor
    }
    
    private func startPresetTimer() {
        // Haptic feedback
        HapticFeedbackManager.shared.timerStarted()
        
        viewModel.currentMode = preset.mode
        
        switch preset.mode {
        case .pomodoro:
            viewModel.focusDuration = preset.duration
        case .timer:
            viewModel.timerDuration = preset.duration
        case .focus:
            viewModel.focusDuration = preset.duration
        case .stopwatch:
            break
        }
        
        viewModel.startSession(plannedDuration: preset.duration)
        
        LOG_UI(.info, "QuickPresets", "Started timer from preset: \(preset.name) (\(preset.duration)s)")
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        }
    }
}

// MARK: - Color Helper Extension

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#if DEBUG
#Preview {
    QuickPresetsView(viewModel: TimerPageViewModel.shared)
        .padding()
}
#endif
