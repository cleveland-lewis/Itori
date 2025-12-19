//
//  WatchRootView.swift
//  Roots (watchOS)
//

#if os(watchOS)
import SwiftUI

struct WatchRootView: View {
    var body: some View {
        VStack {
            Text("Roots Watch")
            Text("Timer + Focus")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
#endif
