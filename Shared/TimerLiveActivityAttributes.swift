//
//  TimerLiveActivityAttributes.swift
//  Roots
//
//  Shared between main app and widget extension
//  Created on 12/24/24.
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
        
        public init(mode: String, label: String, remainingSeconds: Int, 
                   elapsedSeconds: Int, isRunning: Bool, isOnBreak: Bool) {
            self.mode = mode
            self.label = label
            self.remainingSeconds = remainingSeconds
            self.elapsedSeconds = elapsedSeconds
            self.isRunning = isRunning
            self.isOnBreak = isOnBreak
        }
    }

    public var activityID: String
    
    public init(activityID: String) {
        self.activityID = activityID
    }
}
#endif
