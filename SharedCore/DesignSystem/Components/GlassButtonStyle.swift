import SwiftUI

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        GlassButton(configuration: configuration)
    }

    private struct GlassButton: View {
        let configuration: Configuration
        @EnvironmentObject private var settings: AppSettings
        @Environment(\.colorScheme) private var colorScheme

        var body: some View {
            configuration.label
                .padding(DesignSystem.Layout.padding.card)
                .frame(width: 48, height: 48)
                .background(DesignSystem.Materials.hud)
                .opacity(configuration.isPressed ? 0.6 : settings.glassOpacity(for: colorScheme))
                .clipShape(Circle())
                .shadow(color: DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.12), radius: 16, x: 0, y: 8)
                .symbolEffect(.bounce)
                .onHover { hovering in
                        #if canImport(AppKit)
                        if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        #endif
                    }
        }
    }
}

// Keep file for legacy GlassButtonStyle only.

extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle { GlassButtonStyle() }
}
