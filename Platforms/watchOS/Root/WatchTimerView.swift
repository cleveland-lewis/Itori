//
//  WatchTimerView.swift
//  Itori (watchOS)
//

#if os(watchOS)
    import SwiftUI

    struct WatchTimerView: View {
        @EnvironmentObject var syncManager: WatchSyncManager
        @AppStorage("watchTimerDisplayStyle") private var displayStyle: String = "digital"
        @AppStorage("watchDefaultTimerMode") private var defaultTimerMode: String = "pomodoro"
        @State private var selectedMode: TimerMode = .pomodoro
        @State private var customMinutes: Int = 25

        private var displayTime: String {
            let seconds = syncManager.timerSecondsRemaining
            let mins = seconds / 60
            let secs = seconds % 60
            return String(format: "%02d:%02d", mins, secs)
        }

        private var isActive: Bool {
            syncManager.activeTimer != nil
        }

        private var currentMode: TimerMode {
            if let activeTimer = syncManager.activeTimer {
                return activeTimer.mode
            }
            return TimerMode(rawValue: defaultTimerMode) ?? .pomodoro
        }

        var body: some View {
            ScrollView {
                VStack(spacing: 16) {
                    // Timer Display
                    Group {
                        if displayStyle == "analog" {
                            AnalogTimerDisplay(secondsRemaining: syncManager.timerSecondsRemaining)
                        } else {
                            DigitalTimerDisplay(displayTime: displayTime)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )

                    if let timer = syncManager.activeTimer {
                        Text(timer.mode.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Controls
                    if isActive {
                        // Active Session - Pause and Stop buttons
                        VStack(spacing: 12) {
                            // Mode is locked during session
                            HStack {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                Text(NSLocalizedString(
                                    "Mode locked during session",
                                    value: "Mode locked during session",
                                    comment: ""
                                ))
                                .font(.caption2)
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                            HStack(spacing: 12) {
                                // Pause/Resume button
                                Button(action: togglePause) {
                                    Label(
                                        syncManager.isTimerPaused ? NSLocalizedString(
                                            "Resume",
                                            value: "Resume",
                                            comment: ""
                                        ) : NSLocalizedString("Pause", value: "Pause", comment: ""),
                                        systemImage: syncManager.isTimerPaused ? "play.fill" : "pause.fill"
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(syncManager.isTimerPaused ? .green : .orange)

                                // Stop button
                                Button(action: stopTimer) {
                                    Label(
                                        NSLocalizedString("Stop", value: "Stop", comment: ""),
                                        systemImage: "stop.fill"
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                            }
                        }
                    } else {
                        // No Active Session - Show mode picker and start
                        VStack(spacing: 12) {
                            // Mode Picker (only when no active session)
                            Picker("Mode", selection: $selectedMode) {
                                Text(NSLocalizedString("Pomodoro", value: "Pomodoro", comment: ""))
                                    .tag(TimerMode.pomodoro)
                                Text(NSLocalizedString("Timer", value: "Timer", comment: "")).tag(TimerMode.timer)
                                Text(NSLocalizedString("Stopwatch", value: "Stopwatch", comment: ""))
                                    .tag(TimerMode.stopwatch)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)

                            // Custom Duration (for specific modes)
                            if selectedMode == .timer {
                                Stepper("\(customMinutes) min", value: $customMinutes, in: 1 ... 120, step: 5)
                                    .font(.caption)
                                    .padding(.horizontal)
                            }

                            // Start Button
                            Button(action: startTimer) {
                                Label(NSLocalizedString("Start", value: "Start", comment: ""), systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Timer")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(.ultraThinMaterial)
            .onAppear {
                // Initialize selected mode from settings
                selectedMode = TimerMode(rawValue: defaultTimerMode) ?? .pomodoro
            }
        }

        private func startTimer() {
            let duration: Int? = switch selectedMode {
            case .timer:
                customMinutes * 60
            case .stopwatch:
                nil
            default:
                selectedMode.defaultDuration
            }

            syncManager.startTimer(mode: selectedMode, durationSeconds: duration)
        }

        private func stopTimer() {
            syncManager.stopTimer()
        }

        private func togglePause() {
            if syncManager.isTimerPaused {
                syncManager.resumeTimer()
            } else {
                syncManager.pauseTimer()
            }
        }
    }

    // MARK: - Timer Display Components

    private struct DigitalTimerDisplay: View {
        let displayTime: String

        var body: some View {
            VStack(spacing: 8) {
                Text(displayTime)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .padding()
        }
    }

    private struct AnalogTimerDisplay: View {
        let secondsRemaining: Int

        private var progress: Double {
            guard secondsRemaining > 0 else { return 0 }
            let totalSeconds = 25 * 60 // Default to 25 minutes for display
            return Double(secondsRemaining) / Double(totalSeconds)
        }

        var body: some View {
            VStack(spacing: 8) {
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)

                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.blue,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    // Time display in center
                    Text(verbatim: "\(secondsRemaining / 60)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }

                Text(NSLocalizedString("minutes", value: "minutes", comment: ""))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }

#endif
