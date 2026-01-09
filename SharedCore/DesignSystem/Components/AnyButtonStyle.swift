import SwiftUI

/// Type eraser so we can choose button styles at runtime.
struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init(_ style: some ButtonStyle) {
        _makeBody = { configuration in AnyView(style.makeBody(configuration: configuration)) }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}
