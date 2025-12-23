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

// MARK: - Environment Key

private struct LayoutMetricsKey: EnvironmentKey {
    static let defaultValue = LayoutMetrics(compactMode: false, largeTapTargets: false)
}

extension EnvironmentValues {
    public var layoutMetrics: LayoutMetrics {
        get { self[LayoutMetricsKey.self] }
        set { self[LayoutMetricsKey.self] = newValue }
    }
}

extension View {
    public func layoutMetrics(_ metrics: LayoutMetrics) -> some View {
        environment(\.layoutMetrics, metrics)
    }
}
