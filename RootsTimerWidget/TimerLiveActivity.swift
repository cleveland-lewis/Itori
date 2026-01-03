//
//  TimerLiveActivity.swift
//  RootsTimerWidget
//
//  Created on 12/24/24.
//

#if canImport(ActivityKit)
import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerLiveActivityAttributes.self) { context in
            // Lock screen/banner UI
            LiveActivityView(context: context)
                .activityBackgroundTint(Color(red: 0.0, green: 0.5, blue: 0.9).opacity(0.15))
                .activitySystemActionForegroundColor(Color.primary)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            if let emoji = context.state.activityEmoji {
                                Text(emoji)
                                    .font(.caption)
                            } else {
                                Image(systemName: iconName(for: context.state.mode))
                                    .foregroundColor(.accentColor)
                                    .font(.caption)
                            }
                            Text(context.state.label)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        
                        // Phase 3.2: Show activity name
                        if let activityName = context.state.activityName {
                            Text(activityName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(timeString(context.state.remainingSeconds))
                            .font(.title3.monospacedDigit())
                            .fontWeight(.semibold)
                        if context.state.isRunning {
                            Text("remaining")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        ProgressView(value: progress(context.state))
                            .tint(context.state.isOnBreak ? .orange : .blue)
                        
                        HStack {
                            // Phase 3.2: Pomodoro cycle or mode
                            if let currentCycle = context.state.pomodoroCurrentCycle,
                               let totalCycles = context.state.pomodoroTotalCycles {
                                HStack(spacing: 3) {
                                    Image(systemName: "flame.fill")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    Text("\(currentCycle)/\(totalCycles)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text(context.state.mode)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            Text("\(Int(progress(context.state) * 100))%")
                                .font(.caption2.monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } compactLeading: {
                // Compact leading (emoji or timer icon)
                if let emoji = context.state.activityEmoji {
                    Text(emoji)
                        .font(.caption)
                } else {
                    Image(systemName: iconName(for: context.state.mode))
                        .foregroundColor(context.state.isOnBreak ? .orange : .blue)
                }
            } compactTrailing: {
                // Compact trailing (time remaining)
                Text(compactTimeString(context.state.remainingSeconds))
                    .font(.caption2.monospacedDigit())
                    .fontWeight(.medium)
            } minimal: {
                // Minimal view (emoji or icon with status)
                if let emoji = context.state.activityEmoji {
                    Text(emoji)
                        .font(.caption2)
                } else {
                    Image(systemName: context.state.isRunning ? "timer" : "pause.circle.fill")
                        .foregroundColor(context.state.isOnBreak ? .orange : .blue)
                }
            }
        }
    }
    
    private func progress(_ state: TimerLiveActivityAttributes.ContentState) -> Double {
        let total = Double(state.elapsedSeconds + state.remainingSeconds)
        guard total > 0 else { return 0 }
        return Double(state.elapsedSeconds) / total
    }
    
    private func iconName(for mode: String) -> String {
        switch mode.lowercased() {
        case "pomodoro": return "timer"
        case "stopwatch": return "stopwatch"
        case "countdown": return "timer"
        default: return "timer"
        }
    }
    
    private func timeString(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    private func compactTimeString(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Live Activity View

@available(iOS 16.1, *)
struct LiveActivityView: View {
    let context: ActivityViewContext<TimerLiveActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with activity name (Phase 3.2)
            HStack {
                HStack(spacing: 6) {
                    if let emoji = context.state.activityEmoji {
                        Text(emoji)
                            .font(.system(size: 18))
                    } else {
                        Image(systemName: iconName)
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if let activityName = context.state.activityName {
                            Text(activityName)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                        }
                        Text(context.state.mode)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeString(context.state.remainingSeconds))
                        .font(.title2.monospacedDigit())
                        .fontWeight(.bold)
                    Text(context.state.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            VStack(spacing: 6) {
                ProgressView(value: progress)
                    .tint(context.state.isOnBreak ? .orange : .blue)
                    .frame(height: 8)
                
                HStack {
                    Text("Elapsed: \(timeString(context.state.elapsedSeconds))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))% complete")
                        .font(.caption2.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
            
            // Phase 3.2: Pomodoro cycle indicator
            if let currentCycle = context.state.pomodoroCurrentCycle,
               let totalCycles = context.state.pomodoroTotalCycles {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("Cycle \(currentCycle) of \(totalCycles)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Status indicator
            if !context.state.isRunning {
                HStack(spacing: 4) {
                    Image(systemName: "pause.circle.fill")
                        .font(.caption)
                    Text("Paused")
                        .font(.caption)
                }
                .foregroundColor(.orange)
            }
        }
        .padding(16)
    }
    
    private var progress: Double {
        let total = Double(context.state.elapsedSeconds + context.state.remainingSeconds)
        guard total > 0 else { return 0 }
        return Double(context.state.elapsedSeconds) / total
    }
    
    private var iconName: String {
        switch context.state.mode.lowercased() {
        case "pomodoro": return "timer"
        case "stopwatch": return "stopwatch"
        case "countdown": return "timer"
        default: return "timer"
        }
    }
    
    private func timeString(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

#endif
