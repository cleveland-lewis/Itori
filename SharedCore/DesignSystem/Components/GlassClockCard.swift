import SwiftUI

/// Glassy container that lets the clock float above the background with a neutral hairline and subtle highlight.
struct GlassClockCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = DesignSystem.Layout.cornerRadiusLarge
    var paddingAmount: CGFloat = DesignSystem.Layout.padding.card
    var content: () -> Content

    var body: some View {
        #if os(macOS)
            content()
                .padding(paddingAmount)
                .background(
                    DesignSystem.Materials.card,
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                        .allowsHitTesting(false)
                )
        #else
            content()
                .padding(paddingAmount)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.9), lineWidth: 1)
                        .allowsHitTesting(false)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.14 : 0.08),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(0.9)
                        .allowsHitTesting(false)
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.18), radius: 22, x: 0, y: 14)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.10), radius: 10, x: 0, y: 6)
        #endif
    }
}
