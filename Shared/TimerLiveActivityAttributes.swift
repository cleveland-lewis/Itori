//
//  TimerLiveActivityAttributes.swift
//  Roots
//
//  Shared between main app and widget extension
//  Phase 3.1: Enhanced with activity name and pomodoro progress
//

import Foundation

#if canImport(ActivityKit)
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
        
        // Phase 3.1: Enhanced properties
        public var activityName: String?           // Name of linked TimerActivity
        public var activityEmoji: String?          // Emoji of linked TimerActivity
        public var pomodoroCurrentCycle: Int?      // Current pomodoro cycle (1-based)
        public var pomodoroTotalCycles: Int?       // Total cycles before long break
        
        public init(mode: String, label: String, remainingSeconds: Int, 
                   elapsedSeconds: Int, isRunning: Bool, isOnBreak: Bool,
                   activityName: String? = nil, activityEmoji: String? = nil,
                   pomodoroCurrentCycle: Int? = nil, pomodoroTotalCycles: Int? = nil) {
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
