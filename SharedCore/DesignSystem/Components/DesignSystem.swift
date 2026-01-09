import SwiftUI
#if os(macOS)
    import AppKit
#elseif os(watchOS)
    import SwiftUI
#else
    import UIKit
#endif

enum DesignMaterial: String, CaseIterable, Identifiable, Hashable {
    var id: String { rawValue }
    case ultraThin, regular, thick

    var material: Material {
        switch self {
        case .ultraThin: .ultraThinMaterial
        case .regular: .regularMaterial
        case .thick: .thickMaterial
        }
    }

    var name: String {
        switch self {
        case .ultraThin: "Ultra Thin"
        case .regular: "Regular"
        case .thick: "Thick"
        }
    }
}

enum DesignSystem {
    // Global empty state message used across the app
    static let emptyStateMessage = "No data available"

    enum Colors {
        static let primary = Color("Primary")
        static let secondary = Color("Secondary")
        static let destructive = Color.red
        static let subtle = Color("Subtle")
        static let neutral = Color("Neutral")

        /// Global accent color - inherits the app-wide accent
        /// Apply this to all generic UI elements (buttons, toggles, selections, etc.)
        /// DO NOT use for semantic colors (event categories, course colors, status indicators)
        static var accent: Color { .accentColor }

        // Semantic macOS / iOS colors to match Apple HIG
        static var appBackground: Color {
            #if os(macOS)
                return Color(nsColor: .windowBackgroundColor)
            #elseif os(watchOS)
                return Color.black
            #else
                return Color(uiColor: .systemBackground)
            #endif
        }

        static var sidebarBackground: Color {
            #if os(macOS)
                return Color(nsColor: .controlBackgroundColor)
            #elseif os(watchOS)
                return Color.black
            #else
                return Color(uiColor: .secondarySystemBackground)
            #endif
        }

        static var cardBackground: Color {
            #if os(macOS)
                return Color(nsColor: NSColor(
                    calibratedRed: 39.0 / 255.0,
                    green: 39.0 / 255.0,
                    blue: 40.0 / 255.0,
                    alpha: 1.0
                ))
            #elseif os(watchOS)
                return Color.black.opacity(0.85)
            #else
                return Color(uiColor: .secondarySystemBackground).opacity(0.92)
            #endif
        }

        static var groupedBackground: Color {
            #if os(macOS)
                return Color(nsColor: .underPageBackgroundColor)
            #elseif os(watchOS)
                return Color.black
            #else
                return Color(uiColor: .systemGroupedBackground)
            #endif
        }

        static var liquidMaterial: Material { DesignSystem.Materials.hud }

        static func background(for _: ColorScheme) -> Color {
            appBackground
        }

        /// Semantic neutral line color that inverts by color scheme:
        /// - Light mode: charcoal (matches dark-mode app background)
        /// - Dark mode: white (matches light-mode app background)
        static func neutralLine(for colorScheme: ColorScheme) -> Color {
            #if os(macOS)
                func resolvedBackground(_ appearanceName: NSAppearance.Name) -> NSColor {
                    var color = NSColor.windowBackgroundColor
                    if let appearance = NSAppearance(named: appearanceName) {
                        appearance.performAsCurrentDrawingAppearance {
                            color = NSColor.windowBackgroundColor
                        }
                    }
                    return color
                }
                let lightBackground = resolvedBackground(.aqua)
                let darkBackground = resolvedBackground(.darkAqua)
                // Invert: light scheme gets the dark background (charcoal), dark scheme gets light background (white)
                return colorScheme == .dark ? Color(lightBackground) : Color(darkBackground)
            #elseif os(watchOS)
                return Color.gray.opacity(colorScheme == .dark ? 0.6 : 0.4)
            #else
                let lightTrait = UITraitCollection(userInterfaceStyle: .light)
                let darkTrait = UITraitCollection(userInterfaceStyle: .dark)
                let light = UIColor.systemBackground.resolvedColor(with: lightTrait)
                let dark = UIColor.systemBackground.resolvedColor(with: darkTrait)
                return colorScheme == .dark ? Color(light) : Color(dark)
            #endif
        }
    }

    // MARK: - Layout (8pt Grid)

    enum Layout {
        enum spacing {
            static let small: CGFloat = 8
            static let medium: CGFloat = 16
            static let large: CGFloat = 24
            static let extraLarge: CGFloat = 32
        }

        enum padding {
            static let window: CGFloat = 20
            static let card: CGFloat = 16
        }

        static let cornerRadiusSmall: CGFloat = 12
        static let cornerRadiusStandard: CGFloat = 16
        static let cornerRadiusLarge: CGFloat = 24

        // Shared sizing tokens for rows and pills
        enum rowHeight {
            static let small: CGFloat = 32
            static let medium: CGFloat = 44
            static let large: CGFloat = 56
        }

        enum radii {
            static let card: CGFloat = 22
            static let block: CGFloat = 15
            static let pill: CGFloat = 10
        }
    }

    // Backwards-compatible spacing tokens
    enum Spacing {
        static let xsmall: CGFloat = 4
        static let small: CGFloat = Layout.spacing.small
        static let medium: CGFloat = Layout.spacing.medium
        static let large: CGFloat = Layout.spacing.large
    }

    // MARK: - Typography (Semantic Styles)

    enum Typography {
        static let display = Font.largeTitle.weight(.bold)
        static let header = Font.title2.bold()
        static let subHeader = Font.headline.weight(.medium)
        static let body = Font.body
        static let caption = Font.caption

        // Backwards-compatible aliases
        static let title = Font.title2.weight(.semibold)
    }

    enum Materials {
        // Semantic materials aligned to Apple HIG guidance
        static let sidebar: Material = .ultraThinMaterial
        static var card: AnyShapeStyle {
            AnyShapeStyle(.regularMaterial)
        }

        static var cardOpacity: Double {
            0.88
        }

        static let popup: Material = .thickMaterial
        static let hud: Material = .ultraThinMaterial
        // Surface materials used by smaller components
        static let surface: Material = .regularMaterial
        static let surfaceHover: Material = .thickMaterial
    }

    enum Corners {
        static let small: CGFloat = Layout.cornerRadiusSmall
        static let medium: CGFloat = Layout.cornerRadiusStandard
        static let large: CGFloat = Layout.cornerRadiusLarge
        static let card: CGFloat = Layout.radii.card
        static let block: CGFloat = Layout.radii.block
        static let pill: CGFloat = Layout.radii.pill
    }

    enum Icons {
        static let primary = Image(systemName: "star.fill")
        static let settings = Image(systemName: "gearshape")
    }

    enum Cards {
        static let cornerRadius: CGFloat = Corners.medium
        static let inset: CGFloat = Spacing.small
        static let defaultHeight: CGFloat = 260
        // new unified card metrics
        static let cardMinWidth: CGFloat = 260
        static let cardMinHeight: CGFloat = 140
        static let cardCornerRadius: CGFloat = 18
    }

    // semantic helpers
    static func background(for colorScheme: ColorScheme) -> Color {
        Colors.background(for: colorScheme)
    }

    static var materials: [DesignMaterial] { DesignMaterial.allCases }
}
