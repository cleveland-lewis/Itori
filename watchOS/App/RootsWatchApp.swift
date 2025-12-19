//
//  RootsWatchApp.swift
//  Roots (watchOS)
//

#if os(watchOS)
import SwiftUI

@main
struct RootsWatchApp: App {
    @StateObject private var timerManager = TimerManager()
    @StateObject private var focusManager = FocusManager()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(timerManager)
                .environmentObject(focusManager)
        }
    }
}
#endif
