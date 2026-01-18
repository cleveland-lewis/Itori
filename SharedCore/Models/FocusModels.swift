#if !os(watchOS)
    import Foundation
    import SwiftUI

    // Timer models - use the new Timer* types from TimerModels.swift
    typealias LocalTimerMode = TimerMode
    typealias LocalTimerActivity = TimerActivity
    typealias LocalTimerSession = FocusSession
#endif
