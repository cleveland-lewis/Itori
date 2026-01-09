import SwiftUI

// MARK: - Liquid Glass Button Style

public struct ItoriLiquidButtonStyle: ButtonStyle {
    public var cornerRadius: CGFloat = 12
    public var verticalPadding: CGFloat = 8
    public var horizontalPadding: CGFloat = 14

    public init(cornerRadius: CGFloat = 12, verticalPadding: CGFloat = 8, horizontalPadding: CGFloat = 14) {
        self.cornerRadius = cornerRadius
        self.verticalPadding = verticalPadding
        self.horizontalPadding = horizontalPadding
    }

    public func makeBody(configuration: Configuration) -> some View {
        ItoriLiquidButton(
            configuration: configuration,
            cornerRadius: cornerRadius,
            vPad: verticalPadding,
            hPad: horizontalPadding
        )
    }

    private struct ItoriLiquidButton: View {
        let configuration: Configuration
        let cornerRadius: CGFloat
        let vPad: CGFloat
        let hPad: CGFloat
        @State private var isHovering: Bool = false
        @EnvironmentObject private var preferences: AppPreferences

        var body: some View {
            let reducedMotion = preferences.reduceMotion
            let highContrast = preferences.highContrast

            configuration.label
                .font(DesignSystem.Typography.body)
                .foregroundColor(.primary)
                .padding(.vertical, vPad)
                .padding(.horizontal, hPad)
                .background {
                    #if os(macOS)
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(AnyShapeStyle(DesignSystem.Colors.sidebarBackground))
                    #else
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(highContrast
                                ? AnyShapeStyle(Color.primary.opacity(0.08))
                                : AnyShapeStyle(DesignSystem.Materials.hud))
                    #endif
                }
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.primary.opacity(isHovering ? 0.1 : 0))
                        .animation(.easeInOut(duration: 0.1), value: isHovering)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.primary.opacity(0.03))
                )
            #if !os(macOS)
                .shadow(color: Color.black.opacity(isHovering ? 0.06 : 0.03), radius: isHovering ? 10 : 6, x: 0, y: 4)
            #endif
                .scaleEffect(reducedMotion ? 1.0 : (configuration.isPressed ? 0.92 : 1.0))
                .animation(
                    reducedMotion ? .none : DesignSystem.Motion.interactiveSpring,
                    value: configuration.isPressed
                )
                .animation(reducedMotion ? .none : DesignSystem.Motion.interactiveSpring, value: isHovering)
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .onHover { hover in
                    isHovering = hover
                }
        }
    }
}

// MARK: - Accent Toggle Style (looks like a button)

public struct ItoriAccentToggleStyle: ToggleStyle {
    public var cornerRadius: CGFloat = 12
    public var paddingV: CGFloat = 8
    public var paddingH: CGFloat = 14

    public init(cornerRadius: CGFloat = 12, paddingV: CGFloat = 8, paddingH: CGFloat = 14) {
        self.cornerRadius = cornerRadius
        self.paddingV = paddingV
        self.paddingH = paddingH
    }

    public func makeBody(configuration: Configuration) -> some View {
        AccentToggleContent(
            configuration: configuration,
            cornerRadius: cornerRadius,
            paddingV: paddingV,
            paddingH: paddingH
        )
    }

    private struct AccentToggleContent: View {
        let configuration: Configuration
        let cornerRadius: CGFloat
        let paddingV: CGFloat
        let paddingH: CGFloat
        @State private var isHovering: Bool = false

        var body: some View {
            HStack {
                configuration.label
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(foregroundColor(isOn: configuration.isOn))
                    .padding(.vertical, paddingV)
                    .padding(.horizontal, paddingH)
                    .frame(maxWidth: .infinity)
            }
            .background(backgroundView(isOn: configuration.isOn))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(isHovering ? 0.1 : 0))
                    .animation(.easeInOut(duration: 0.1), value: isHovering)
            )
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onTapGesture { configuration.isOn.toggle() }
            .onHover { hover in
                isHovering = hover
            }
        }

        private func backgroundView(isOn: Bool) -> some View {
            Group {
                if isOn {
                    // Prominent glassy accent
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.accentColor.opacity(0.90))
                    #if os(macOS)
                        .background(DesignSystem.Colors.sidebarBackground)
                    #else
                        .background(DesignSystem.Materials.hud)
                    #endif
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(Color.accentColor.opacity(0.12))
                                .blur(radius: 6)
                        )
                    #if !os(macOS)
                        .shadow(color: Color.accentColor.opacity(0.25), radius: 12, x: 0, y: 6)
                    #endif
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    #if os(macOS)
                        .fill(DesignSystem.Colors.sidebarBackground)
                    #else
                        .fill(DesignSystem.Materials.hud)
                    #endif
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(Color.primary.opacity(0.03))
                        )
                    #if !os(macOS)
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
                    #endif
                }
            }
        }

        private func foregroundColor(isOn: Bool) -> Color {
            isOn ? Color.white : Color.primary
        }
    }
}

// MARK: - Icon-only circular button helper

// Note: ItoriIconButton is defined in Components/ItoriIconButton.swift
// GlassIconButton is defined in GlassIconButton.swift

// Convenience extensions for quick usage
public extension ButtonStyle where Self == ItoriLiquidButtonStyle {
    static var itariLiquid: ItoriLiquidButtonStyle { ItoriLiquidButtonStyle() }
}

public extension ToggleStyle where Self == ItoriAccentToggleStyle {
    static var itariAccent: ItoriAccentToggleStyle { ItoriAccentToggleStyle() }
}
