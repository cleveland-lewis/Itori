import SwiftUI

// MARK: - Centered Content Column Contract

/// Architectural layout solution for consistent horizontal centering across all pages.
///
/// ## Problem Solved:
/// Content containers (cards, grids, lists) were drifting left/right during window resizing
/// because each page used different approaches:
/// - Some used fixed `.padding(.horizontal)` which doesn't scale
/// - Some used GeometryReader with manual calculations
/// - Some had hardcoded offsets or leading padding
/// - No shared contract meant inconsistent behavior
///
/// ## Solution:
/// Single reusable component that:
/// 1. Outer container expands to full available width
/// 2. Inner container constrains to readable maximum width
/// 3. Inner container centers horizontally automatically
/// 4. Responsive padding scales with window size
/// 5. Works across all platforms (macOS, iOS, iPadOS)
///
/// ## Usage:
/// ```swift
/// ScrollView {
///     CenteredContentColumn { geometry in
///         let contentWidth = geometry.size.width
///         // Your page content here using contentWidth
///         // Cards, grids, lists, etc.
///     }
/// }
/// ```

public struct CenteredContentColumn<Content: View>: View {
    private let maxWidth: CGFloat
    private let debugMode: Bool
    private let content: (GeometryProxy) -> Content

    /// Create a centered content column with geometry access
    /// - Parameters:
    ///   - maxWidth: Maximum width constraint for content (default: 1400)
    ///   - debugMode: Show visual outline for debugging (default: false, compile-out in release)
    ///   - content: The page content builder that receives geometry
    public init(
        maxWidth: CGFloat = 1400,
        debugMode: Bool = false,
        @ViewBuilder content: @escaping (GeometryProxy) -> Content
    ) {
        self.maxWidth = maxWidth
        #if DEBUG
            self.debugMode = debugMode
        #else
            self.debugMode = false
        #endif
        self.content = content
    }

    public var body: some View {
        GeometryReader { outerGeometry in
            let availableWidth = outerGeometry.size.width
            let contentWidth = min(availableWidth, maxWidth)
            let shouldConstrainWidth = availableWidth > maxWidth

            // Calculate responsive padding based on available width
            let basePadding = responsivePadding(for: availableWidth)

            ScrollView {
                GeometryReader { innerGeometry in
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)

                        content(innerGeometry)
                            .frame(
                                maxWidth: shouldConstrainWidth ? contentWidth : .infinity,
                                alignment: .center
                            )
                            .padding(.horizontal, basePadding)
                        #if DEBUG
                            .border(debugMode ? Color.red : Color.clear, width: 1)
                            .overlay(alignment: .topTrailing) {
                                if debugMode {
                                    Text(verbatim: "CCC: \(Int(contentWidth))pt")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                        .padding(4)
                                        .background(Color.black.opacity(0.7))
                                }
                            }
                        #endif

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
        }
    }

    /// Calculate responsive horizontal padding based on available width
    /// - Narrow windows: Minimum padding for readable margins
    /// - Medium windows: Proportional padding
    /// - Wide windows: Maximum padding with centered content constraint
    private func responsivePadding(for width: CGFloat) -> CGFloat {
        #if os(macOS)
            // macOS responsive padding curve
            switch width {
            case ..<600:
                return 16 // Narrow: minimum margins
            case 600 ..< 900:
                return 20 // Comfortable reading
            case 900 ..< 1200:
                return 24 // Standard desktop
            case 1200 ..< 1600:
                return 32 // Wide desktop
            default:
                return 40 // Ultra-wide: generous margins
            }
        #elseif os(iOS)
            // iOS/iPadOS responsive padding
            switch width {
            case ..<400:
                return 16 // iPhone portrait
            case 400 ..< 600:
                return 20 // iPhone landscape / small iPad
            case 600 ..< 900:
                return 32 // iPad portrait
            case 900 ..< 1200:
                return 40 // iPad landscape
            default:
                return 48 // iPad Pro / split view
            }
        #else
            // Fallback for other platforms
            return width < 600 ? 16 : 24
        #endif
    }
}

// MARK: - Simple Version Without Geometry

public struct SimpleCenteredContent<Content: View>: View {
    private let content: Content
    private let maxWidth: CGFloat
    private let debugMode: Bool

    public init(
        maxWidth: CGFloat = 1400,
        debugMode: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.maxWidth = maxWidth
        #if DEBUG
            self.debugMode = debugMode
        #else
            self.debugMode = false
        #endif
        self.content = content()
    }

    public var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let contentWidth = min(availableWidth, maxWidth)
            let shouldConstrainWidth = availableWidth > maxWidth
            let basePadding = responsivePadding(for: availableWidth)

            HStack(spacing: 0) {
                Spacer(minLength: 0)

                content
                    .frame(
                        maxWidth: shouldConstrainWidth ? contentWidth : .infinity,
                        alignment: .center
                    )
                    .padding(.horizontal, basePadding)
                #if DEBUG
                    .border(debugMode ? Color.red : Color.clear, width: 1)
                #endif

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func responsivePadding(for width: CGFloat) -> CGFloat {
        #if os(macOS)
            switch width {
            case ..<600: return 16
            case 600 ..< 900: return 20
            case 900 ..< 1200: return 24
            case 1200 ..< 1600: return 32
            default: return 40
            }
        #elseif os(iOS)
            switch width {
            case ..<400: return 16
            case 400 ..< 600: return 20
            case 600 ..< 900: return 32
            case 900 ..< 1200: return 40
            default: return 48
            }
        #else
            return width < 600 ? 16 : 24
        #endif
    }
}

// MARK: - Layout Tokens Extension

public extension LayoutMetrics {
    /// Standard maximum content width for centered layouts
    static let maxContentWidth: CGFloat = 1400

    /// Narrow maximum content width for reading-focused pages
    static let maxReadingWidth: CGFloat = 900
}
