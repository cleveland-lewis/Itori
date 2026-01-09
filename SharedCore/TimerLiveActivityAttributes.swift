//
//  TimerLiveActivityAttributes.swift
//  Itori
//
//  Shared between main app and widget extension
//

import Foundation

#if os(iOS)
    import ActivityKit

    @available(iOS 16.1, *)
    public struct TimerLiveActivityAttributes: ActivityAttributes {
        public struct ContentState: Codable, Hashable {
            public var mode: String
            public var label: String
            public var remainingSeconds: Int
            public var elapsedSeconds: Int
            public var isRunning: Bool
            public var isOnBreak: Bool
            public var activityName: String?
            public var activityEmoji: String?
            public var pomodoroCurrentCycle: Int?
            public var pomodoroTotalCycles: Int?

            public init(
                mode: String,
                label: String,
                remainingSeconds: Int,
                elapsedSeconds: Int,
                isRunning: Bool,
                isOnBreak: Bool,
                activityName: String? = nil,
                activityEmoji: String? = nil,
                pomodoroCurrentCycle: Int? = nil,
                pomodoroTotalCycles: Int? = nil
            ) {
                self.mode = mode
                self.label = label
                self.remainingSeconds = remainingSeconds
                self.elapsedSeconds = elapsedSeconds
                self.isRunning = isRunning
                self.isOnBreak = isOnBreak
                self.activityName = activityName
                self.activityEmoji = activityEmoji
                self.pomodoroCurrentCycle = pomodoroCurrentCycle
                self.pomodoroTotalCycles = pomodoroTotalCycles
            }
        }

        public var activityID: String

        public init(activityID: String) {
            self.activityID = activityID
        }
    }
#endif
