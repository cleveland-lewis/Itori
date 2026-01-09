//
//  TimerLiveActivityManager.swift
//  Itori (iOS)
//

#if os(iOS)
    import Combine
    import Foundation
    #if canImport(ActivityKit)
        import ActivityKit

        final class IOSTimerLiveActivityManager: ObservableObject {
            private var activity: Activity<TimerLiveActivityAttributes>?
            private var lastUpdate: Date?
            private let minUpdateInterval: TimeInterval =
                2.0 // Phase 3.3: Increased to 2 seconds for battery efficiency
            private var lastContentState: TimerLiveActivityAttributes.ContentState?
            private var significantChangeThreshold: Int =
                5 // Phase 3.3: Only update if remaining seconds changed by at least 5

            var isAvailable: Bool {
                if #available(iOS 16.1, *) {
                    return ActivityAuthorizationInfo().areActivitiesEnabled
                }
                return false
            }

            var isActive: Bool {
                activity != nil
            }

            func sync(
                currentMode: TimerMode,
                session: FocusSession?,
                elapsed: TimeInterval,
                remaining: TimeInterval,
                isOnBreak: Bool,
                activities: [TimerActivity],
                pomodoroCompletedCycles: Int,
                pomodoroMaxCycles: Int
            ) {
                guard #available(iOS 16.1, *) else { return }
                guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                    Task { await end() }
                    return
                }

                guard let session else {
                    Task { await end() }
                    return
                }

                if session.state == .completed || session.state == .cancelled {
                    Task { await end() }
                    return
                }

                let label: String = if currentMode == .pomodoro {
                    isOnBreak ? NSLocalizedString("alarm.break", comment: "Break") : NSLocalizedString(
                        "alarm.work",
                        comment: "Work"
                    )
                } else {
                    currentMode.displayName
                }

                // Phase 3.1: Get activity name and emoji
                var activityName: String?
                var activityEmoji: String?
                if let activityID = session.activityID,
                   let activity = activities.first(where: { $0.id == activityID })
                {
                    activityName = activity.name
                    activityEmoji = activity.emoji
                }

                // Phase 3.1: Pomodoro cycle information
                var pomodoroCurrentCycle: Int?
                var pomodoroTotalCycles: Int?
                if currentMode == .pomodoro && !isOnBreak {
                    pomodoroCurrentCycle = pomodoroCompletedCycles + 1 // 1-based for display
                    pomodoroTotalCycles = pomodoroMaxCycles
                }

                let contentState = TimerLiveActivityAttributes.ContentState(
                    mode: currentMode.displayName,
                    label: label,
                    remainingSeconds: max(Int(remaining.rounded()), 0),
                    elapsedSeconds: max(Int(elapsed.rounded()), 0),
                    isRunning: session.state == .running,
                    isOnBreak: isOnBreak,
                    activityName: activityName,
                    activityEmoji: activityEmoji,
                    pomodoroCurrentCycle: pomodoroCurrentCycle,
                    pomodoroTotalCycles: pomodoroTotalCycles
                )
                lastContentState = contentState

                if activity == nil {
                    let attributes = TimerLiveActivityAttributes(activityID: session.id.uuidString)
                    Task { await start(attributes: attributes, contentState: contentState) }
                    return
                }

                Task { await update(contentState: contentState) }
            }

            @available(iOS 16.1, *)
            private func start(
                attributes: TimerLiveActivityAttributes,
                contentState: TimerLiveActivityAttributes.ContentState
            ) async {
                do {
                    if #available(iOS 16.2, *) {
                        let content = ActivityContent(state: contentState, staleDate: nil)
                        activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
                    } else {
                        activity = try Activity.request(
                            attributes: attributes,
                            contentState: contentState,
                            pushType: nil
                        )
                    }
                    lastUpdate = Date()
                } catch {
                    activity = nil
                }
            }

            @available(iOS 16.1, *)
            private func update(contentState: TimerLiveActivityAttributes.ContentState) async {
                // Phase 3.3: Enhanced throttling logic
                let now = Date()

                // Time-based throttling
                if let last = lastUpdate, now.timeIntervalSince(last) < minUpdateInterval {
                    return
                }

                // Significant change detection
                if let lastState = lastContentState {
                    let remainingDiff = abs(contentState.remainingSeconds - lastState.remainingSeconds)
                    let isStatusChange = contentState.isRunning != lastState.isRunning
                    let isModeChange = contentState.isOnBreak != lastState.isOnBreak

                    // Only update if:
                    // 1. Status changed (running/paused)
                    // 2. Mode changed (work/break)
                    // 3. Significant time change (>= threshold)
                    if !isStatusChange && !isModeChange && remainingDiff < significantChangeThreshold {
                        return
                    }
                }

                lastUpdate = now
                guard let live = activity else { return }
                if #available(iOS 16.2, *) {
                    let content = ActivityContent(state: contentState, staleDate: nil)
                    await live.update(content)
                } else {
                    await live.update(using: contentState)
                }
            }

            func end() async {
                guard #available(iOS 16.1, *) else { return }
                guard let live = activity else { return }
                if #available(iOS 16.2, *) {
                    let content = ActivityContent(
                        state: lastContentState ??
                            .init(
                                mode: "",
                                label: "",
                                remainingSeconds: 0,
                                elapsedSeconds: 0,
                                isRunning: false,
                                isOnBreak: false
                            ),
                        staleDate: nil
                    )
                    await live.end(content, dismissalPolicy: .immediate)
                } else {
                    await live.end(
                        using: lastContentState ??
                            .init(
                                mode: "",
                                label: "",
                                remainingSeconds: 0,
                                elapsedSeconds: 0,
                                isRunning: false,
                                isOnBreak: false
                            ),
                        dismissalPolicy: .immediate
                    )
                }
                activity = nil
                lastUpdate = nil
            }
        }
    #else
        final class IOSTimerLiveActivityManager: ObservableObject {
            func sync(
                currentMode _: TimerMode,
                session _: FocusSession?,
                elapsed _: TimeInterval,
                remaining _: TimeInterval,
                isOnBreak _: Bool,
                activities _: [TimerActivity],
                pomodoroCompletedCycles _: Int,
                pomodoroMaxCycles _: Int
            ) {}
        }
    #endif
#endif
