import Foundation
import SwiftUI

// DEPRECATED: These types are now defined in TimerModels.swift
// Keeping file for potential migration but types are commented out
/*
 enum LocalTimerMode: String, CaseIterable, Identifiable, Codable {
     case pomodoro
     case countdown
     case stopwatch

     var id: String { rawValue }

     var label: String {
         switch self {
         case .pomodoro: "Pomodoro"
         case .countdown: "Timer"
         case .stopwatch: "Stopwatch"
         }
     }
 }

 struct LocalTimerActivity: Identifiable, Hashable {
     let id: UUID
     var name: String
     var category: String
     var courseCode: String?
     var assignmentTitle: String?
     var colorTag: ColorTag
     var isPinned: Bool
     var totalTrackedSeconds: TimeInterval
     var todayTrackedSeconds: TimeInterval
 }

 struct LocalTimerSession: Identifiable, Codable, Hashable {
     let id: UUID
     var activityID: UUID
     var mode: LocalTimerMode
     var startDate: Date
     var endDate: Date?
     var duration: TimeInterval
     var workSeconds: TimeInterval
     var breakSeconds: TimeInterval
     var isBreakSession: Bool

     enum CodingKeys: String, CodingKey {
         case id, activityID, mode, startDate, endDate, duration, workSeconds, breakSeconds, isBreakSession
     }

     init(
         id: UUID,
         activityID: UUID,
         mode: LocalTimerMode,
         startDate: Date,
         endDate: Date?,
         duration: TimeInterval,
         workSeconds: TimeInterval? = nil,
         breakSeconds: TimeInterval? = nil,
         isBreakSession: Bool = false
     ) {
         self.id = id
         self.activityID = activityID
         self.mode = mode
         self.startDate = startDate
         self.endDate = endDate
         self.duration = duration
         self.isBreakSession = isBreakSession

         // For Pomodoro mode, distinguish work vs break time
         if mode == .pomodoro {
             if isBreakSession {
                 self.workSeconds = 0
                 self.breakSeconds = duration
             } else {
                 self.workSeconds = duration
                 self.breakSeconds = 0
             }
         } else {
             // For stopwatch and timer, all time is work time
             self.workSeconds = workSeconds ?? duration
             self.breakSeconds = breakSeconds ?? 0
         }
     }
 }
 */
