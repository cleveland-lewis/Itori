import SwiftUI

struct OverlayInsetsKey: EnvironmentKey {
    static let defaultValue: EdgeInsets = .init()
}

extension EnvironmentValues {
    var overlayInsets: EdgeInsets {
        get { self[OverlayInsetsKey.self] }
        set { self[OverlayInsetsKey.self] = newValue }
    }
}

extension View {
    func contentSafeInsetsForOverlay() -> some View {
        modifier(OverlayContentInsetsModifier())
    }
}

private struct OverlayContentInsetsModifier: ViewModifier {
    @Environment(\.overlayInsets) private var overlayInsets

    func body(content: Content) -> some View {
        content
            .padding(.top, overlayInsets.top)
            .padding(.trailing, overlayInsets.trailing)
    }
}
