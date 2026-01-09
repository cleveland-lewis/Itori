import SwiftUI

struct CircleIconButton: View {
    let icon: String
    let iconColor: Color
    let size: CGFloat
    var backgroundMaterial: Material = DesignSystem.Materials.hud
    var backgroundOpacity: Double = 1
    var showsBorder: Bool = false
    var borderColor: Color = .primary.opacity(0.06)
    var borderWidth: CGFloat = 1
    var iconRotation: Angle = .zero
    var accessibilityLabel: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(iconColor)
                .rotationEffect(iconRotation)
                .frame(width: size, height: size)
                .background(
                    Circle()
                    #if os(macOS)
                        .fill(DesignSystem.Colors.sidebarBackground)
                        .opacity(backgroundOpacity)
                    #else
                        .fill(backgroundMaterial)
                        .opacity(backgroundOpacity)
                    #endif
                )
                .overlay {
                    if showsBorder {
                        Circle()
                            .strokeBorder(borderColor, lineWidth: borderWidth)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .itariStandardInteraction()
        .focusEffectDisabled(true)
        .accessibilityLabelWithTooltip(accessibilityLabel ?? icon)
    }
}
