import SwiftUI

/// Example integration of Phase A timer enhancements into existing timer view
/// This demonstrates how to add the new features with feature flags
///
/// INTEGRATION GUIDE:
/// 1. Import this file or copy patterns into your existing IOSTimerPageView.swift
/// 2. Add feature flag checks around new UI components
/// 3. Keep existing UI unchanged when flags are OFF
///
struct TimerPageIntegrationExample: View {
    @ObservedObject var viewModel: TimerPageViewModel
    @Environment(\.featureFlags) var featureFlags
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // PHASE A FEATURE 1: Quick Timer Presets
                // Add this ABOVE or BELOW existing timer display
                if featureFlags.quickTimerPresets {
                    QuickPresetsView(
                        viewModel: viewModel,
                        presets: viewModel.allPresets()
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // EXISTING TIMER DISPLAY (unchanged)
                // OR
                // PHASE A FEATURE 2: Dynamic Countdown Visuals
                if featureFlags.dynamicCountdownVisuals {
                    // New: Dynamic visuals (ring or grid)
                    DynamicCountdownView(viewModel: viewModel)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    // Existing: Your current timer display
                    ExistingTimerDisplayView(viewModel: viewModel)
                        .transition(.opacity)
                }
                
                // EXISTING TIMER CONTROLS (unchanged)
                TimerControlButtonsExample(viewModel: viewModel)
                
                Spacer()
            }
            .animation(.easeInOut(duration: 0.3), value: featureFlags.dynamicCountdownVisuals)
            .animation(.easeInOut(duration: 0.3), value: featureFlags.quickTimerPresets)
            .navigationTitle("Timer")
            .toolbar {
                // PHASE A FEATURE 3: Timer Hub
                // Add navigation to Timer Hub in toolbar
                if featureFlags.timerHub {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: TimerHubView(viewModel: viewModel)) {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }
                        .accessibilityLabel("View timer history")
                    }
                }
                
                // Feature flag settings (debug only)
                #if DEBUG
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: FeatureFlagsSettingsView()) {
                        Label("Flags", systemImage: "flag")
                    }
                }
                #endif
            }
        }
    }
}

// MARK: - Placeholder for existing timer display

private struct ExistingTimerDisplayView: View {
    @ObservedObject var viewModel: TimerPageViewModel
    
    var body: some View {
        // Replace this with your actual timer display
        VStack(spacing: 12) {
            Text(formatTime(viewModel.sessionRemaining))
                .font(.system(size: 64, weight: .semibold, design: .rounded))
                .monospacedDigit()
            
            if viewModel.currentSession?.state == .paused {
                Text("Paused")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 280)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Placeholder for existing controls

private struct TimerControlButtonsExample: View {
    @ObservedObject var viewModel: TimerPageViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            if viewModel.currentSession == nil {
                Button("Start") {
                    viewModel.startSession()
                }
                .buttonStyle(.borderedProminent)
            } else {
                if viewModel.currentSession?.state == .running {
                    Button("Pause") {
                        viewModel.pauseSession()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Resume") {
                        viewModel.resumeSession()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("Stop") {
                    viewModel.endSession(completed: false)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
    }
}

// MARK: - Integration Examples

/// Example 1: Minimal Integration
/// Just add Quick Presets above timer
struct MinimalIntegration: View {
    @ObservedObject var viewModel: TimerPageViewModel
    @Environment(\.featureFlags) var featureFlags
    
    var body: some View {
        VStack {
            // NEW: Quick presets (if enabled)
            if featureFlags.quickTimerPresets {
                QuickPresetsView(viewModel: viewModel)
            }
            
            // EXISTING: Your timer view
            YourExistingTimerView()
        }
    }
    
    @ViewBuilder
    func YourExistingTimerView() -> some View {
        Text("Your existing timer UI here")
    }
}

/// Example 2: Full Integration
/// Replace timer display + add presets + add hub
struct FullIntegration: View {
    @ObservedObject var viewModel: TimerPageViewModel
    @Environment(\.featureFlags) var featureFlags
    
    var body: some View {
        NavigationStack {
            VStack {
                // NEW: Quick presets at top
                if featureFlags.quickTimerPresets {
                    QuickPresetsView(viewModel: viewModel)
                }
                
                // NEW or EXISTING: Timer display
                if featureFlags.dynamicCountdownVisuals {
                    DynamicCountdownView(viewModel: viewModel)
                } else {
                    ExistingTimerDisplayView(viewModel: viewModel)
                }
                
                // EXISTING: Controls
                TimerControlButtonsExample(viewModel: viewModel)
            }
            .toolbar {
                // NEW: Hub link
                if featureFlags.timerHub {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: TimerHubView(viewModel: viewModel)) {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                    }
                }
            }
        }
    }
}

/// Example 3: Conditional Toolbar Integration
struct ToolbarIntegration: View {
    @ObservedObject var viewModel: TimerPageViewModel
    @Environment(\.featureFlags) var featureFlags
    
    var body: some View {
        YourExistingView()
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // NEW: Timer Hub button
                    if featureFlags.timerHub {
                        NavigationLink(destination: TimerHubView(viewModel: viewModel)) {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }
                    }
                    
                    // EXISTING: Other toolbar items
                    Button(action: {}) {
                        Image(systemName: "gear")
                    }
                }
            }
    }
    
    @ViewBuilder
    func YourExistingView() -> some View {
        Text("Your existing view")
    }
}

// MARK: - Settings Integration Example

/// Example: Add feature flag toggle to settings
struct SettingsIntegrationExample: View {
    var body: some View {
        Form {
            // EXISTING SETTINGS SECTIONS
            Section("Timer Settings") {
                // ... your existing settings ...
            }
            
            // NEW: Phase A Features section
            #if DEBUG
            Section("Experimental Features") {
                NavigationLink("Feature Flags", destination: FeatureFlagsSettingsView())
            } footer: {
                Text("Enable new timer features for testing. These features are in beta and may change.")
            }
            #endif
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Integration Example") {
    TimerPageIntegrationExample(viewModel: TimerPageViewModel.shared)
        .environment(\.featureFlags, FeatureFlags.shared)
}

#Preview("Minimal") {
    MinimalIntegration(viewModel: TimerPageViewModel.shared)
        .environment(\.featureFlags, FeatureFlags.shared)
}

#Preview("Full") {
    FullIntegration(viewModel: TimerPageViewModel.shared)
        .environment(\.featureFlags, FeatureFlags.shared)
}
#endif
