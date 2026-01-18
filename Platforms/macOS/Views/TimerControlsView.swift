#if os(macOS)
    import SwiftUI

    struct TimerControlsView: View {
        @ObservedObject var viewModel: TimerPageViewModel
        @Binding var currentMode: TimerMode
        @Environment(\.colorScheme) private var colorScheme
        @StateObject private var animationPolicy = AnimationPolicy.shared

        var body: some View {
            VStack(spacing: 16) {
                VStack(spacing: DesignSystem.Layout.spacing.small) {
                    Text(timeDisplay)
                        .font(DesignSystem.Typography.body)
                        .monospacedDigit()
                        .foregroundColor(.primary)
                        .shadow(
                            color: DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.12),
                            radius: 10,
                            x: 0,
                            y: 10
                        )

                    Text(modeSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .shadow(color: DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.12), radius: 10, x: 0, y: 10)

                HStack(spacing: 12) {
                    // Primary play/pause button with morphing animation
                    playPauseButton

                    button(
                        label: viewModel.currentSession == nil ? "Reset" : "End",
                        systemImage: "stop.fill",
                        prominent: false
                    ) {
                        if viewModel.currentSession == nil {
                            resetDefaults()
                        } else {
                            viewModel.endSession(completed: false)
                        }
                    }

                    // Skip button for Pomodoro mode only, when running
                    if currentMode == .pomodoro && viewModel.currentSession?.state == .running {
                        button(label: "Skip", systemImage: "forward.fill", prominent: false) {
                            viewModel.skipSegment()
                        }
                    }
                }

                if currentMode == .pomodoro {
                    HStack(spacing: 12) {
                        durationControl(
                            title: "Focus",
                            duration: $viewModel.focusDuration,
                            symbol: "flame",
                            isDisabled: viewModel.currentSession?.state == .running
                        )
                        durationControl(
                            title: "Break",
                            duration: $viewModel.breakDuration,
                            symbol: "cup.and.saucer",
                            isDisabled: viewModel.currentSession?.state == .running
                        )
                        Label(
                            viewModel.isOnBreak ? "Break" : "Focus",
                            systemImage: viewModel.isOnBreak ? "leaf" : "bolt.fill"
                        )
                        .font(.subheadline.weight(.semibold))
                        .padding(10)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(
                            cornerRadius: DesignSystem.Layout.cornerRadiusStandard,
                            style: .continuous
                        ))
                    }
                } else if currentMode == .timer {
                    durationControl(
                        title: "Duration",
                        duration: $viewModel.timerDuration,
                        symbol: "clock",
                        isDisabled: viewModel.currentSession?.state == .running
                    )
                }
            }
            .padding(DesignSystem.Layout.padding.card)
            .background(DesignSystem.Materials.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }

        // MARK: - Play/Pause Morphing Button

        private var playPauseButton: some View {
            let isRunning = viewModel.currentSession?.state == .running
            let isPaused = viewModel.currentSession?.state == .paused

            let icon = isRunning ? "pause.fill" : "play.fill"
            let label = isRunning ? "Pause" : (isPaused ? "Resume" : "Start")

            let action: () -> Void = {
                if isRunning {
                    animationPolicy.withAnimation(.essential) {
                        viewModel.pauseSession()
                    }
                } else if isPaused {
                    animationPolicy.withAnimation(.essential) {
                        viewModel.resumeSession()
                    }
                } else {
                    animationPolicy.withAnimation(.essential) {
                        viewModel.startSession(plannedDuration: currentMode == .timer ? viewModel.timerDuration : nil)
                    }
                }
            }

            return Button(action: action) {
                Label(label, systemImage: icon)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.itoriLiquidProminent)
            .animationPolicy(.essential, value: isRunning)
        }

        private func button(
            label: String,
            systemImage: String,
            prominent: Bool,
            action: @escaping () -> Void
        ) -> some View {
            let style = prominent ? AnyButtonStyle(ItoriLiquidProminentButtonStyle()) :
                AnyButtonStyle(ItoriLiquidButtonStyle())
            return Button(action: action) {
                Label(label, systemImage: systemImage)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(style)
        }

        private func durationControl(
            title: String,
            duration: Binding<TimeInterval>,
            symbol: String,
            isDisabled: Bool = false
        ) -> some View {
            VStack(alignment: .leading, spacing: 6) {
                Label(title, systemImage: symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                HStack {
                    Slider(
                        value: Binding(get: { duration.wrappedValue / 60 }, set: { duration.wrappedValue = $0 * 60 }),
                        in: 5 ... 120,
                        step: 5
                    )
                    .disabled(isDisabled)
                    Text(verbatim: "\(Int(duration.wrappedValue / 60))m")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                        .frame(width: 44)
                }
            }
            .padding(10)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusStandard, style: .continuous))
            .opacity(isDisabled ? 0.5 : 1.0)
        }

        private var timeDisplay: String {
            if let session = viewModel.currentSession, session.state != .idle {
                if session.mode == .stopwatch {
                    return format(seconds: Int(viewModel.sessionElapsed))
                } else {
                    let remaining = viewModel.sessionRemaining > 0 ? viewModel
                        .sessionRemaining : (session.plannedDuration ?? 0)
                    return format(seconds: Int(remaining))
                }
            }

            switch currentMode {
            case .pomodoro:
                return format(seconds: Int(viewModel.focusDuration))
            case .timer:
                return format(seconds: Int(viewModel.timerDuration))
            case .stopwatch:
                return "00:00"
            case .focus:
                return format(seconds: Int(viewModel.focusDuration))
            }
        }

        private var modeSubtitle: String {
            switch currentMode {
            case .pomodoro:
                viewModel.isOnBreak ? "Pomodoro — Break" : "Pomodoro — Focus Block"
            case .timer:
                "Timer — Countdown"
            case .stopwatch:
                "Stopwatch"
            case .focus:
                "Focus Mode"
            }
        }

        private func format(seconds: Int) -> String {
            let h = seconds / 3600
            let m = (seconds % 3600) / 60
            let s = seconds % 60
            if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
            return String(format: "%02d:%02d", m, s)
        }

        private func resetDefaults() {
            viewModel.sessionElapsed = 0
            viewModel.sessionRemaining = 0
        }
    }
#endif
