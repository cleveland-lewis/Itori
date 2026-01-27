import SwiftUI

/// Feature flag controls for development and testing
/// Only visible in debug builds or when dev mode is enabled
struct FeatureFlagsSettingsView: View {
    @ObservedObject var flags = FeatureFlags.shared
    @AppStorage("Itori.devModeEnabled") private var devMode = false
    
    var body: some View {
        #if DEBUG
        Form {
            content
        }
        .navigationTitle("Feature Flags")
        #else
        if devMode {
            Form {
                content
            }
            .navigationTitle("Feature Flags")
        } else {
            EmptyView()
        }
        #endif
    }
    
    @ViewBuilder
    private var content: some View {
        Section {
            Text("Feature flags control new functionality. Flags default to OFF for stability.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        
        Section("Phase A - Core Safe Wins") {
            Toggle("Dynamic Countdown Visuals", isOn: $flags.dynamicCountdownVisuals)
                .help("Ring and grid visualization modes for timer countdown")
            
            Toggle("Quick Timer Presets", isOn: $flags.quickTimerPresets)
                .help("Pre-configured timer durations with customization")
            
            Toggle("Timer Hub", isOn: $flags.timerHub)
                .help("History view and analytics for completed timers")
        }
        
        Section("Phase B - Extensions") {
            Toggle("Timer Themes", isOn: $flags.timerThemes)
                .help("Custom color schemes and visual styles")
            
            Toggle("Timer Insights", isOn: $flags.timerInsights)
                .help("Advanced statistics and productivity metrics")
        }
        
        Section("Phase C - Experimental") {
            Toggle("AI Timer Suggestions", isOn: $flags.aiTimerSuggestions)
                .help("Intelligent timer recommendations based on usage")
            
            Toggle("Cross-Device Sync", isOn: $flags.crossDeviceSync)
                .help("Real-time timer sync across devices")
            
            Toggle("Timer Collaboration", isOn: $flags.timerCollaboration)
                .help("Shared timers with other users")
        }
        
        Section("Platform Features") {
            #if os(iOS)
            Toggle("Dynamic Island Timer", isOn: $flags.dynamicIslandTimer)
                .help("Show timer progress in Dynamic Island")
            
            Toggle("Lock Screen Enhancements", isOn: $flags.lockScreenWidgetEnhancements)
                .help("Enhanced timer widgets on lock screen")
            #endif
            
            #if os(macOS)
            Toggle("Menu Bar Enhancements", isOn: $flags.menuBarTimerEnhancements)
                .help("Enhanced timer display in menu bar")
            #endif
        }
        
        Section("Development") {
            #if DEBUG
            Toggle("Enable All Timer Features", isOn: $flags.enableAllTimerFeatures)
                .help("Enable all timer features for testing")
            
            Toggle("High-Precision Timer Tick", isOn: $flags.highPrecisionTimerTick)
                .help("Use high-precision timer for debugging")
            #endif
        }
        
        Section("Quick Actions") {
            Button("Enable Phase A") {
                flags.enablePhaseA()
            }
            
            Button("Enable Phase B") {
                flags.enablePhaseB()
            }
            
            Button("Enable Phase C") {
                flags.enablePhaseC()
            }
            
            #if DEBUG
            Button("Enable All (Dev)") {
                flags.enableAllForDevelopment()
            }
            .foregroundColor(.orange)
            #endif
            
            Button("Disable All Enhancements") {
                flags.disableAllTimerEnhancements()
            }
            .foregroundColor(.red)
            
            Button("Reset to Defaults") {
                flags.resetToDefaults()
            }
            .foregroundColor(.secondary)
        }
        
        Section("Status") {
            LabeledContent("Phase A Features") {
                Text(flags.hasPhaseAFeatures ? "Enabled" : "Disabled")
                    .foregroundColor(flags.hasPhaseAFeatures ? .green : .secondary)
            }
            
            LabeledContent("Phase B Features") {
                Text(flags.hasPhaseBFeatures ? "Enabled" : "Disabled")
                    .foregroundColor(flags.hasPhaseBFeatures ? .green : .secondary)
            }
            
            LabeledContent("Phase C Features") {
                Text(flags.hasPhaseCFeatures ? "Enabled" : "Disabled")
                    .foregroundColor(flags.hasPhaseCFeatures ? .green : .secondary)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        FeatureFlagsSettingsView()
    }
}
#endif
