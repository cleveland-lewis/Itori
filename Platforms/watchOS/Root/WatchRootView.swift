//
//  WatchRootView.swift
//  Roots (watchOS)
//

#if os(watchOS)
import SwiftUI

struct WatchRootView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Roots")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text("Watch App")
                .font(.headline)
            
            Text("If you see this, the app is working!")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

#endif
