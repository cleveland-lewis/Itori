import SwiftUI

struct GlassBlueProminentButtonStyle: ButtonStyle {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        #if os(macOS)
            configuration.label
                .font(DesignSystem.Typography.subHeader)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Cards.cardCornerRadius, style: .continuous)
                        .fill(Color.accentColor)
                )
                .opacity(configuration.isPressed ? 0.9 : 1.0)
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
        #else
            let policy = MaterialPolicy(preferences: preferences)

            configuration.label
                .font(DesignSystem.Typography.subHeader)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.Cards.cardCornerRadius, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color.accentColor.opacity(0.85), Color.accentColor],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                        if !preferences.reduceTransparency {
                            RoundedRectangle(cornerRadius: DesignSystem.Cards.cardCornerRadius, style: .continuous)
                                .fill(DesignSystem.Materials.card)
                                .opacity(0.15)
                        }
                        RoundedRectangle(cornerRadius: DesignSystem.Cards.cardCornerRadius, style: .continuous)
                            .strokeBorder(
                                DesignSystem.Colors.neutralLine(for: colorScheme).opacity(policy.borderOpacity * 2.3),
                                lineWidth: policy.borderWidth * 0.5
                            )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Cards.cardCornerRadius, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.12))
                        .blendMode(.softLight)
                        .opacity(configuration.isPressed ? 0.25 : 0)
                )
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
                .contentShape(Rectangle())
                .onHover { hovering in
                    #if canImport(AppKit)
                        if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    #endif
                }
        #endif
    }
}

extension ButtonStyle where Self == GlassBlueProminentButtonStyle {
    static var glassBlueProminent: GlassBlueProminentButtonStyle { GlassBlueProminentButtonStyle() }
}
