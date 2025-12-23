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

    init() {
        // Register watchOS feedback service
        Task { @MainActor in
            FeedbackCoordinator.shared.register(service: watchOSFeedbackService())
        }
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(timerManager)
                .environmentObject(focusManager)
        }
    }
}
#endif
