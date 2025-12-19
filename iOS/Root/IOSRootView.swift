//
//  IOSRootView.swift
//  Roots (iOS)
//

#if os(iOS)
import SwiftUI

struct IOSRootView: View {
    var body: some View {
        Text("Roots iOS")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignSystem.Colors.appBackground)
    }
}
#endif
