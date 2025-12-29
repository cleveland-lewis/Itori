//
//  RootsWatchApp.swift
//  Roots (watchOS)
//

#if os(watchOS)
import SwiftUI

@main
struct RootsWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchRootView()
        }
    }
}
#endif
