import SwiftUI
#if canImport(AppKit)
    import AppKit
#endif
#if canImport(UIKit)
    import UIKit
#endif

// Compatibility shim for legacy helpers. The canonical definitions live in
// DesignSystem/DesignTokens.swift and Components/. This file now only hosts
// helpers that are not defined elsewhere to avoid redeclaration errors.

// MARK: - Spacing

enum ItariSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let section: CGFloat = 40
    static let pagePadding: CGFloat = 20 // Consistent horizontal page padding for macOS
}

// MARK: - Radius

enum ItariRadius {
    static let card: CGFloat = 24
    static let popup: CGFloat = 20
    static let chip: CGFloat = 12
}

// MARK: - Colors

enum ItariColor {
    static func glassBorder(for colorScheme: ColorScheme) -> Color {
        DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.16)
    }

    static var textPrimary: Color { .primary }
    static var textSecondary: Color { .secondary }
    static var label: Color { .primary }
    static var secondaryLabel: Color { .secondary }
    static var cardBackground: Color { DesignSystem.Colors.cardBackground }
    static var inputBackground: Color {
        #if canImport(AppKit)
            return Color(nsColor: NSColor.textBackgroundColor)
        #elseif canImport(UIKit)
            return Color(uiColor: UIColor.secondarySystemBackground)
        #else
            return .secondary
        #endif
    }

    static var subtleFill: Color { Color(nsColor: .controlBackgroundColor).opacity(0.4) }
    static var accent: Color { .accentColor }
    static var calendarDensityLow: Color { Color.green.opacity(0.8) }
    static var calendarDensityMedium: Color { Color.yellow.opacity(0.85) }
    static var calendarDensityHigh: Color { Color.red.opacity(0.88) }
}

// MARK: - Typography

extension Text {
    func itariSectionHeader() -> some View {
        font(.system(size: 14, weight: .semibold))
    }

    func itariBody() -> some View {
        font(.system(size: 13, weight: .regular))
    }

    func itoriBodySecondary() -> some View {
        font(.system(size: 13)).foregroundColor(.secondary)
    }

    func itoriCaption() -> some View {
        font(.footnote).foregroundColor(.secondary)
    }
}

extension View {
    func itoriSystemBackground() -> some View {
        background(Color(nsColor: .windowBackgroundColor))
    }

    func itoriCardBackground(radius: CGFloat = ItariRadius.card) -> some View {
        #if os(macOS)
            background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(DesignSystem.Materials.card)
                    .opacity(DesignSystem.Materials.cardOpacity)
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .modifier(NeutralLineOverlay(radius: radius, opacity: 0.6))
        #else
            background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(DesignSystem.Materials.card)
                    .opacity(DesignSystem.Materials.cardOpacity)
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .modifier(NeutralLineOverlay(radius: radius, opacity: 0.12))
        #endif
    }

    func itoriGlassBackground(opacity: Double = 0.2, radius: CGFloat = ItariRadius.card) -> some View {
        #if os(macOS)
            background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(DesignSystem.Materials.card)
                    .opacity(DesignSystem.Materials.cardOpacity)
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        #else
            background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(DesignSystem.Materials.card)
                    .opacity(opacity * DesignSystem.Materials.cardOpacity)
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        #endif
    }

    func itoriFloatingShadow() -> some View {
        shadow(color: Color.primary.opacity(0.12), radius: 20, y: 10)
    }

    func itoriCardShadow() -> some View {
        shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
    }
}

private struct NeutralLineOverlay: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var radius: CGFloat
    var opacity: Double

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(DesignSystem.Colors.neutralLine(for: colorScheme).opacity(opacity), lineWidth: 1)
        )
    }
}

// MARK: - Components

struct ItoriPopupContainer<Content: View, Footer: View>: View {
    var title: String
    var subtitle: String?
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: ItariSpacing.l) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).itariSectionHeader()
                if let subtitle { Text(subtitle).itoriCaption() }
            }
            Divider()
            content
            Divider()
            footer
        }
        .padding(.horizontal, ItariSpacing.xl)
        .padding(.vertical, ItariSpacing.l)
        .frame(maxWidth: 560)
        .background(
            DesignSystem.Materials.popup,
            in: RoundedRectangle(cornerRadius: ItariRadius.popup, style: .continuous)
        )
        .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: ItariRadius.popup, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .popupTextAlignedLeft()
        #if os(macOS)
            .onExitCommand {
                dismiss()
            }
        #endif
    }
}

struct ItoriFormRow<Control: View, Helper: View>: View {
    var label: String
    @ViewBuilder var control: Control
    @ViewBuilder var helper: Helper

    init(label: String, @ViewBuilder control: () -> Control, @ViewBuilder helper: () -> Helper = { EmptyView() }) {
        self.label = label
        self.control = control()
        self.helper = helper()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: ItariSpacing.m) {
                Text(label)
                    .itoriBodySecondary()
                    .frame(width: 110, alignment: Alignment.leading)
                control
            }
            helper
        }
    }
}

struct ItoriCard<Content: View>: View {
    var title: String?
    var subtitle: String?
    var icon: String?
    var footer: AnyView?
    var compact: Bool = false
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? ItariSpacing.m : 12) {
            if title != nil || icon != nil || subtitle != nil {
                HStack(spacing: ItariSpacing.s) {
                    if let icon { Image(systemName: icon) }
                    VStack(alignment: .leading, spacing: 2) {
                        if let title { Text(title).itariSectionHeader() }
                        if let subtitle { Text(subtitle).itoriCaption() }
                    }
                    Spacer()
                }
            }

            content

            if let footer {
                Divider()
                footer
            }
        }
        .padding(compact ? ItariSpacing.m : 14)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusStandard, style: .continuous)
                .fill(DesignSystem.Materials.card)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusStandard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusStandard, style: .continuous)
                .stroke(DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
    }
}

struct ItoriFloatingTabBar: View {
    var items: [RootTab]
    @Binding var selected: RootTab
    var mode: TabBarMode
    var onSelect: (RootTab) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width
            let effectiveMode = resolvedTabBarMode(
                userMode: mode,
                availableWidth: availableWidth,
                tabCount: items.count
            )
            HStack(spacing: DesignSystem.Layout.spacing.small) {
                ForEach(items) { tab in
                    let isSelected = tab == selected
                    ItoriTabBarItem(
                        icon: tab.systemImage,
                        title: tab.title,
                        isSelected: isSelected,
                        displayMode: effectiveMode,
                        accessibilityID: "TabBar.\(tab.rawValue)"
                    ) {
                        // Avoid mutating `selected` here. The parent owns the source-of-truth and
                        // will update the binding inside `onSelect`. Double-writing the same state
                        // during a view update can trigger SwiftUI's "Publishing changes..." warning.
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            onSelect(tab)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(DesignSystem.Materials.hud)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(ItariColor.glassBorder(for: colorScheme), lineWidth: 1)
                    )
            )
            .frame(maxWidth: min(availableWidth - 32, 640))
            .frame(maxWidth: .infinity)
        }
        .frame(height: 72)
    }
}

func resolvedTabBarMode(
    userMode: TabBarMode,
    availableWidth: CGFloat,
    tabCount: Int
) -> TabBarMode {
    switch userMode {
    case .iconsOnly:
        return .iconsOnly
    case .textOnly, .iconsAndText:
        let perTabNeeded: CGFloat = userMode == .textOnly ? 80 : 110
        let totalNeeded = perTabNeeded * CGFloat(tabCount) + 16 * CGFloat(tabCount - 1) + 40
        if totalNeeded > availableWidth {
            return .iconsOnly
        } else {
            return userMode
        }
    }
}

struct ItoriTabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let displayMode: TabBarMode
    let accessibilityID: String
    let action: () -> Void

    @State private var isHovering: Bool = false
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: displayMode == .iconsOnly ? 0 : 6) {
                Image(systemName: icon)
                    .font(DesignSystem.Typography.body)

                if displayMode != .iconsOnly {
                    Text(title)
                        .font(DesignSystem.Typography.body)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(minWidth: 44, minHeight: 32)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.09))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(
                        DesignSystem.Colors.neutralLine(for: colorScheme).opacity(isSelected ? 0.3 : 0.16),
                        lineWidth: 0.5
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.accentColor, lineWidth: 2)
                    .opacity(isFocused ? 0.7 : 0)
            )
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .scaleEffect(isHovering ? 1.03 : 1.0)
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .focusable(true)
        .focused($isFocused)
        .accessibilityIdentifier(accessibilityID)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) { isHovering = hovering }
        }
        .onHover { hovering in
            #if canImport(AppKit)
                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            #endif
        }
        .accessibilityLabelWithTooltip(title)
        .hoverTooltip(title: title)
    }
}

private struct HoverTooltipModifier: ViewModifier {
    let title: String
    @State private var isHovering = false
    @State private var showTooltip = false
    @State private var hoverWorkItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if showTooltip {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(DesignSystem.Materials.hud)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
                        )
                        .offset(y: -36)
                        .accessibilityHidden(true)
                }
            }
            .onHover { hovering in
                guard hoverTooltipEnabled else { return }
                isHovering = hovering
                hoverWorkItem?.cancel()
                if hovering {
                    let workItem = DispatchWorkItem {
                        if isHovering {
                            showTooltip = true
                        }
                    }
                    hoverWorkItem = workItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: workItem)
                } else {
                    showTooltip = false
                }
            }
    }

    private var hoverTooltipEnabled: Bool {
        #if os(macOS)
            true
        #elseif os(iOS)
            UIDevice.current.userInterfaceIdiom == .pad
        #else
            false
        #endif
    }
}

private extension View {
    func hoverTooltip(title: String) -> some View {
        modifier(HoverTooltipModifier(title: title))
    }
}

// MARK: - Missing App Components (Stubs)

struct AppPopupContainer<Content: View, Footer: View>: View {
    let title: String
    let subtitle: String?
    let content: Content
    let footer: Footer

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
    }
}

// AppCard is defined in SharedCore/DesignSystem/Components/AppCard.swift

struct AppLiquidButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 8
    var verticalPadding: CGFloat = 8
    var horizontalPadding: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Size Constants

enum SizeConstants {
    static let pricingSize: CGSize = .init(width: 280, height: 340)
    static let largeIconSize: CGFloat = 48
    static let normalTextSize: CGFloat = 14
    static let smallTextSize: CGFloat = 12
    static let mediumTextSize: CGFloat = 16
    static let emptyIconSize: CGFloat = 64
}

// Compatibility aliases
let pricingSize = SizeConstants.pricingSize
let largeIconSize = SizeConstants.largeIconSize
let normalTextSize = SizeConstants.normalTextSize
let smallTextSize = SizeConstants.smallTextSize
let mediumTextSize = SizeConstants.mediumTextSize
let emptyIconSize = SizeConstants.emptyIconSize

// MARK: - Form Components

struct AppFormRow<Content: View>: View {
    let labelText: String
    let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.labelText = label
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(labelText)
                .frame(width: 120, alignment: .trailing)
                .foregroundStyle(.secondary)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }
}

extension Text {
    func itoriSectionHeader() -> some View {
        self.font(.headline).foregroundStyle(.secondary)
    }

    func itoriBody() -> some View {
        self.font(.body)
    }
}

// MARK: - Color Extensions

extension Color {
    static let calendarDensityLow = Color.gray.opacity(0.15)
    static let calendarDensityMedium = Color.gray.opacity(0.25)
    static let calendarDensityHigh = Color.gray.opacity(0.35)
    static let subtleFill = Color.primary.opacity(0.05)
}

// MARK: - Additional Constants

enum AppRadius {
    static let card: CGFloat = 16
    static let button: CGFloat = 12
}

enum AppWindowSizing {
    static let minPopupWidth: CGFloat = 500
    static let minPopupHeight: CGFloat = 600
}

struct BatchReviewSheet: View {
    let state: Any
    let onApprove: () async -> Void
    let onReject: () -> Void

    var body: some View {
        VStack {
            Text("Batch Review (Not Implemented)")
            HStack {
                Button("Reject", action: onReject)
                Button("Approve") {
                    Task { await onApprove() }
                }
            }
        }
        .padding()
    }
}

// MARK: - Additional Color Constants

extension Color {
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let accent = Color.accentColor
}

// MARK: - Toggle Style

struct AppAccentToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Toggle(configuration)
            .tint(.accentColor)
    }
}

extension ToggleStyle where Self == AppAccentToggleStyle {
    static var itoriAccent: AppAccentToggleStyle { AppAccentToggleStyle() }
}
