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
    /// Applies canonical top content inset for pages displayed under pinned headers.
    /// Content will automatically start at the correct Y-position below the header.
    func contentSafeInsetsForOverlay() -> some View {
        modifier(OverlayContentInsetsModifier())
    }
}

private struct OverlayContentInsetsModifier: ViewModifier {
    @Environment(\.overlayInsets) private var overlayInsets
    @Environment(\.appLayout) private var appLayout

    func body(content: Content) -> some View {
        content
            .padding(.top, overlayInsets.top > 0 ? overlayInsets.top : appLayout.topContentInset)
            .padding(.trailing, overlayInsets.trailing)
    }
}
