#if os(iOS)
import SwiftUI

/// Global app shell that provides consistent top bar across all pages
struct IOSAppShell<Content: View>: View {
    @EnvironmentObject private var navigation: IOSNavigationCoordinator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var safeAreaInsets: EdgeInsets = .init()
    
    let content: Content
    let hideNavigationButtons: Bool
    
    init(hideNavigationButtons: Bool = false, @ViewBuilder content: () -> Content) {
        self.hideNavigationButtons = hideNavigationButtons
        self.content = content()
    }
    
    private var shouldShowButtons: Bool {
        if hideNavigationButtons { return false }
        
        // On iPhone (compact width), hide buttons when navigated (back button present)
        if horizontalSizeClass == .compact {
            return navigation.path.isEmpty
        }
        
        // On iPad (regular width), always show buttons
        return true
    }
    
    var body: some View {
        ZStack {
            content
        }
        .readSafeAreaInsets { safeAreaInsets = $0 }
        .overlay(alignment: .bottom) {
            if shouldShowButtons {
                FloatingControls(safeInsets: safeAreaInsets)
                    .zIndex(1000)
            }
        }
    }
}
#endif
