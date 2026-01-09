import SwiftUI

/// Layout metrics computed from app settings
/// Provides consistent spacing and sizing throughout the app
public struct LayoutMetrics {
    let compactMode: Bool
    let largeTapTargets: Bool

    public init(compactMode: Bool, largeTapTargets: Bool) {
        self.compactMode = compactMode
        self.largeTapTargets = largeTapTargets
    }

    // MARK: - Compact Mode Metrics

    public var listRowVerticalPadding: CGFloat {
        compactMode ? 6 : 12
    }

    public var sectionSpacing: CGFloat {
        compactMode ? 12 : 20
    }

    public var cardPadding: CGFloat {
        compactMode ? 12 : 16
    }

    public var listRowMinHeight: CGFloat {
        compactMode ? 36 : 44
    }

    // MARK: - Large Tap Targets

    public var minimumTapTarget: CGFloat {
        largeTapTargets ? 48 : 36
    }

    public var floatingButtonSize: CGFloat {
        largeTapTargets ? 64 : 52
    }

    public var iconButtonSize: CGFloat {
        largeTapTargets ? 44 : 36
    }
}

// MARK: - Global App Layout Contract

/// Canonical layout spacing enforced across all platforms.
/// Single source of truth for top content insets and header clearance.
public struct AppLayout {
    /// Top inset for overlay controls (Quick Add, Settings button)
    public let overlayTopInset: CGFloat

    /// Trailing inset for overlay controls
    public let overlayTrailingInset: CGFloat

    /// Height of the pinned page header
    public let headerHeight: CGFloat

    /// Spacing below header before content begins
    public let headerBottomSpacing: CGFloat

    /// Total top content inset (where page content should begin)
    public var topContentInset: CGFloat {
        overlayTopInset + headerHeight + headerBottomSpacing
    }

    #if os(macOS)
        public static let macOS = AppLayout(
            overlayTopInset: 16,
            overlayTrailingInset: 24,
            headerHeight: 56,
            headerBottomSpacing: 12
        )
    #endif

    #if os(iOS)
        public static let iOS = AppLayout(
            overlayTopInset: 0,
            overlayTrailingInset: 16,
            headerHeight: 0,
            headerBottomSpacing: 0
        )
    #endif
}

private struct AppLayoutKey: EnvironmentKey {
    #if os(macOS)
        static let defaultValue = AppLayout.macOS
    #elseif os(iOS)
        static let defaultValue = AppLayout.iOS
    #else
        static let defaultValue = AppLayout(
            overlayTopInset: 16,
            overlayTrailingInset: 24,
            headerHeight: 56,
            headerBottomSpacing: 12
        )
    #endif
}

public extension EnvironmentValues {
    var appLayout: AppLayout {
        get { self[AppLayoutKey.self] }
        set { self[AppLayoutKey.self] = newValue }
    }
}

// MARK: - Environment Key

private struct LayoutMetricsKey: EnvironmentKey {
    static let defaultValue = LayoutMetrics(compactMode: false, largeTapTargets: false)
}

public extension EnvironmentValues {
    var layoutMetrics: LayoutMetrics {
        get { self[LayoutMetricsKey.self] }
        set { self[LayoutMetricsKey.self] = newValue }
    }
}

public extension View {
    func layoutMetrics(_ metrics: LayoutMetrics) -> some View {
        environment(\.layoutMetrics, metrics)
    }
}
