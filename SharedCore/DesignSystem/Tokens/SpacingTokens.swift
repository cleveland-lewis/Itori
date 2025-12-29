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
}

// MARK: - Dashboard Grid Spacing

extension Space {
    static let dashboardHorizontalPadding: CGFloat = Space.lg // 24
    static let dashboardColumnGap: CGFloat = Space.lg // 24
    static let dashboardRowGap: CGFloat = Space.xl // 32
}

// MARK: - Card Container Tokens

extension Space {
    static let cardPadding: CGFloat = Space.md // 16
    static let cardCornerRadius: CGFloat = 16
    static let cardHeaderSpacing: CGFloat = Space.sm // 12
    static let cardContentSpacing: CGFloat = Space.md // 16
}

// MARK: - Status Strip Spacing

extension Space {
    static let statusStripHorizontalPadding: CGFloat = Space.lg // 24
    static let statusStripVerticalPadding: CGFloat = Space.md // 16
    static let statusStripItemGap: CGFloat = Space.lg // 24
}

// MARK: - Typography-to-Spacing Coupling

enum TypeSpace {
    static let headlineToBody: CGFloat = Space.sm // 12
    static let bodyToMeta: CGFloat = Space.xs // 8
    static let listRowGap: CGFloat = Space.sm // 12
}

// MARK: - Chart-Specific Spacing

extension Space {
    static let chartInset: CGFloat = Space.sm // 12
    static let chartLabelSpacing: CGFloat = Space.xs // 8
    static let chartLegendGap: CGFloat = Space.md // 16
}
