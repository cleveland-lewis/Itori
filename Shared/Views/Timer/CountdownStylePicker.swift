import SwiftUI

/// Picker for selecting countdown visualization style
/// Feature: Phase A - Dynamic Countdown Visuals
struct CountdownStylePicker: View {
    @Binding var selectedStyle: TimerVisualStyle
    
    var body: some View {
        Picker("Countdown Style", selection: $selectedStyle) {
            ForEach(TimerVisualStyle.allCases.filter { $0 == .ring || $0 == .grid }) { style in
                Label(style.displayName, systemImage: style.systemImage)
                    .tag(style)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Countdown visualization style")
    }
}

#if DEBUG
#Preview {
    @Previewable @State var style: TimerVisualStyle = .ring
    CountdownStylePicker(selectedStyle: $style)
        .padding()
}
#endif
