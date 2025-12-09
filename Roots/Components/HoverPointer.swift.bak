import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// Adds a native pointing-hand cursor on hover for clickable controls.
struct HoverPointerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.onHover { hovering in
#if canImport(AppKit)
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
#endif
        }
    }
}

extension View {
    func hoverPointer() -> some View {
        self.modifier(HoverPointerModifier())
    }
}
