import Foundation

// MARK: - Core Spacing Scale

enum Space {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
    static let xxxl: CGFloat = 56

    #if os(macOS)
        // macOS-specific reduced spacing (30-40% less)
        static let macOS_xs: CGFloat = 6
        static let macOS_sm: CGFloat = 8
        static let macOS_md: CGFloat = 10
        static let macOS_lg: CGFloat = 16
        static let macOS_xl: CGFloat = 20
        static let macOS_xxl: CGFloat = 28
    #endif
}

// MARK: - Dashboard Grid Spacing

extension Space {
    #if os(macOS)
        static let dashboardHorizontalPadding: CGFloat = Space.macOS_lg // 16 (was 24)
        static let dashboardColumnGap: CGFloat = Space.macOS_lg // 16 (was 24)
        static let dashboardRowGap: CGFloat = Space.macOS_xl // 20 (was 32)
    #else
        static let dashboardHorizontalPadding: CGFloat = Space.lg // 24
        static let dashboardColumnGap: CGFloat = Space.lg // 24
        static let dashboardRowGap: CGFloat = Space.xl // 32
    #endif
}

// MARK: - Card Container Tokens

extension Space {
    #if os(macOS)
        static let cardPadding: CGFloat = Space.macOS_md // 10 (was 16)
        static let cardCornerRadius: CGFloat = 12 // slightly reduced
        static let cardHeaderSpacing: CGFloat = Space.macOS_sm // 8 (was 12)
        static let cardContentSpacing: CGFloat = Space.macOS_md // 10 (was 16)
    #else
        static let cardPadding: CGFloat = Space.md // 16
        static let cardCornerRadius: CGFloat = 16
        static let cardHeaderSpacing: CGFloat = Space.sm // 12
        static let cardContentSpacing: CGFloat = Space.md // 16
    #endif
}

// MARK: - Status Strip Spacing

extension Space {
    #if os(macOS)
        static let statusStripHorizontalPadding: CGFloat = Space.macOS_lg // 16 (was 24)
        static let statusStripVerticalPadding: CGFloat = Space.macOS_md // 10 (was 16)
        static let statusStripItemGap: CGFloat = Space.macOS_lg // 16 (was 24)
    #else
        static let statusStripHorizontalPadding: CGFloat = Space.lg // 24
        static let statusStripVerticalPadding: CGFloat = Space.md // 16
        static let statusStripItemGap: CGFloat = Space.lg // 24
    #endif
}

// MARK: - Typography-to-Spacing Coupling

enum TypeSpace {
    #if os(macOS)
        static let headlineToBody: CGFloat = Space.macOS_sm // 8 (was 12)
        static let bodyToMeta: CGFloat = Space.macOS_xs // 6 (was 8)
        static let listRowGap: CGFloat = Space.macOS_sm // 8 (was 12)
    #else
        static let headlineToBody: CGFloat = Space.sm // 12
        static let bodyToMeta: CGFloat = Space.xs // 8
        static let listRowGap: CGFloat = Space.sm // 12
    #endif
}

// MARK: - Chart-Specific Spacing

extension Space {
    #if os(macOS)
        static let chartInset: CGFloat = Space.macOS_sm // 8 (was 12)
        static let chartLabelSpacing: CGFloat = Space.macOS_xs // 6 (was 8)
        static let chartLegendGap: CGFloat = Space.macOS_md // 10 (was 16)
    #else
        static let chartInset: CGFloat = Space.sm // 12
        static let chartLabelSpacing: CGFloat = Space.xs // 8
        static let chartLegendGap: CGFloat = Space.md // 16
    #endif
}

// MARK: - Form Spacing (macOS)

#if os(macOS)
    extension Space {
        static let formSectionSpacing: CGFloat = 10
        static let formRowSpacing: CGFloat = 6
    }
#endif
