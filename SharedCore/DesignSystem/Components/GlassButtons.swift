import SwiftUI

struct GlassAccentIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(DesignSystem.Typography.body)
            #if os(macOS)
                .foregroundColor(.primary)
                .frame(width: 28, height: 28)
                .contentShape(Circle())
            #else
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.8))
                        .background(Circle().fill(DesignSystem.Materials.hud))
                )
                .overlay(
                    Circle().stroke(DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.12), lineWidth: 0.75)
                )
                .shadow(color: Color.accentColor.opacity(0.12), radius: 8, y: 4)
                .contentShape(Circle())
            #endif
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            #if canImport(AppKit)
                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            #endif
        }
        .accessibilityLabelWithTooltip(accessibilityLabel)
    }
}

struct GlassSecondaryIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(DesignSystem.Typography.body)
            #if os(macOS)
                .foregroundColor(.primary)
                .frame(width: 28, height: 28)
                .contentShape(Circle())
            #else
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.primary.opacity(0.06))
                        .background(Circle().fill(DesignSystem.Materials.hud))
                )
                .overlay(
                    Circle().stroke(DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.12), lineWidth: 0.75)
                )
                .shadow(color: Color.primary.opacity(0.06), radius: 8, y: 4)
                .contentShape(Circle())
            #endif
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            #if canImport(AppKit)
                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            #endif
        }
        .accessibilityLabelWithTooltip(accessibilityLabel)
    }
}
