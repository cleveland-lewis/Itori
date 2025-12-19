import SwiftUI

struct GlassPopupContainer<Content: View>: View {
    let content: Content
    let onDismiss: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    init(onDismiss: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            Color(nsColor: .underPageBackgroundColor)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            content
                .padding(DesignSystem.Layout.padding.card)
                .background(DesignSystem.Materials.popup)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.14), radius: 24, x: 0, y: 10)
                .transition(.opacity)
        }
    }
}
