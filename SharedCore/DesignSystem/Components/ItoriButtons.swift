import SwiftUI

// MARK: - Liquid Glass Button Style

public struct ItoriLiquidButtonStyle: ButtonStyle {
    public var verticalPadding: CGFloat = 8
    public var horizontalPadding: CGFloat = 14

    public init(verticalPadding: CGFloat = 8, horizontalPadding: CGFloat = 14) {
        self.verticalPadding = verticalPadding
        self.horizontalPadding = horizontalPadding
    }

    public func makeBody(configuration: Configuration) -> some View {
        ItoriLiquidButton(
            configuration: configuration,
            vPad: verticalPadding,
            hPad: horizontalPadding
        )
    }

    private struct ItoriLiquidButton: View {
        let configuration: Configuration
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
                        Capsule()
                            .fill(.ultraThinMaterial)
                    #else
                        Capsule()
                            .fill(highContrast
                                ? AnyShapeStyle(Color.primary.opacity(0.08))
                                : AnyShapeStyle(DesignSystem.Materials.hud))
                    #endif
                }
                .overlay(
                    Capsule()
                        .fill(Color.primary.opacity(isHovering ? 0.1 : 0))
                        .animation(.easeInOut(duration: 0.1), value: isHovering)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.08))
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
                .contentShape(Capsule())
                .onHover { hover in
                    isHovering = hover
                }
        }
    }
}

public struct ItoriLiquidProminentButtonStyle: ButtonStyle {
    public var verticalPadding: CGFloat = 8
    public var horizontalPadding: CGFloat = 14

    public init(verticalPadding: CGFloat = 8, horizontalPadding: CGFloat = 14) {
        self.verticalPadding = verticalPadding
        self.horizontalPadding = horizontalPadding
    }

    public func makeBody(configuration: Configuration) -> some View {
        ItoriLiquidProminentButton(configuration: configuration, vPad: verticalPadding, hPad: horizontalPadding)
    }

    private struct ItoriLiquidProminentButton: View {
        let configuration: Configuration
        let vPad: CGFloat
        let hPad: CGFloat
        @State private var isHovering: Bool = false
        @EnvironmentObject private var preferences: AppPreferences
        @Environment(\.colorScheme) private var colorScheme

        var body: some View {
            let reducedMotion = preferences.reduceMotion
            let baseTint = Color.accentColor
            configuration.label
                .font(DesignSystem.Typography.body)
                .foregroundColor(.white)
                .padding(.vertical, vPad)
                .padding(.horizontal, hPad)
                .background(
                    ZStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [baseTint.opacity(0.85), baseTint],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        if !preferences.reduceTransparency {
                            Capsule()
                                .fill(DesignSystem.Materials.hud)
                                .opacity(0.12)
                        }
                        Capsule()
                            .strokeBorder(
                                DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.35),
                                lineWidth: 0.6
                            )
                    }
                )
                .overlay(
                    Capsule()
                        .fill(Color.white.opacity(configuration.isPressed ? 0.12 : 0.04))
                )
                .scaleEffect(reducedMotion ? 1.0 : (configuration.isPressed ? 0.97 : 1.0))
                .animation(reducedMotion ? .none : .easeOut(duration: 0.15), value: configuration.isPressed)
                .contentShape(Capsule())
                .onHover { hover in
                    isHovering = hover
                }
                .shadow(
                    color: isHovering ? baseTint.opacity(0.25) : baseTint.opacity(0.15),
                    radius: isHovering ? 12 : 8,
                    x: 0,
                    y: 6
                )
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

public extension ButtonStyle where Self == ItoriLiquidProminentButtonStyle {
    static var itoriLiquidProminent: ItoriLiquidProminentButtonStyle { ItoriLiquidProminentButtonStyle() }
}

public extension ToggleStyle where Self == ItoriAccentToggleStyle {
    static var itariAccent: ItoriAccentToggleStyle { ItoriAccentToggleStyle() }
}
