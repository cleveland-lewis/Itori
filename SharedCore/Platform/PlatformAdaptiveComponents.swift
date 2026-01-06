import SwiftUI

// MARK: - Platform-Adaptive Components
/// Components that automatically adapt their behavior based on platform capabilities

// MARK: - Adaptive Navigation Container
struct AdaptiveNavigationContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        switch CapabilityDomain.Navigation.navigationStyle {
        case .stack:
            // iOS/watchOS: Stack navigation
            NavigationStack {
                content
            }
        case .splitView:
            // iPadOS: Split view
            NavigationSplitView {
                content
            } detail: {
                Text(NSLocalizedString("Select an item", value: "Select an item", comment: ""))
                    .foregroundColor(.secondary)
            }
        case .sidebar:
            // macOS: Three-column with sidebar
            NavigationSplitView {
                content
            } detail: {
                Text(NSLocalizedString("Select an item", value: "Select an item", comment: ""))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Adaptive Button
struct AdaptiveButton<Label: View>: View {
    let action: () -> Void
    let label: Label
    
    init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }
    
    var body: some View {
        Button(action: action) {
            label
                .frame(minWidth: CapabilityDomain.Density.minTapTargetSize,
                       minHeight: CapabilityDomain.Density.minTapTargetSize)
        }
        .platformHoverEffect()
    }
}

// MARK: - Adaptive Card
struct AdaptiveCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .platformPadding()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(cardMaterial)
            }
    }
    
    private var cornerRadius: CGFloat {
        switch Platform.current {
        case .watchOS: return 8
        case .iOS: return 12
        case .iPadOS: return 16
        case .macOS: return 12
        }
    }
    
    private var cardMaterial: Material {
        switch Platform.current {
        case .watchOS: return .thick
        case .iOS: return .regularMaterial
        case .iPadOS: return .regularMaterial
        case .macOS: return .thin
        }
    }
}

// MARK: - Adaptive List
struct AdaptiveList<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        #if os(watchOS)
        List {
            content
        }
        .listStyle(.plain)
        #elseif os(iOS)
        List {
            content
        }
        .listStyle(.insetGrouped)
        #elseif os(macOS)
        List {
            content
        }
        .listStyle(.sidebar)
        #else
        List {
            content
        }
        .listStyle(.sidebar)
        #endif
    }
}

// MARK: - Adaptive Toolbar
struct AdaptiveToolbar<Content: View>: View {
    let placement: ToolbarPlacement
    let content: Content
    
    init(placement: ToolbarPlacement = .automatic, @ViewBuilder content: () -> Content) {
        self.placement = placement
        self.content = content()
    }
    
    var body: some View {
        Group {
            if shouldShowToolbar {
                content
            }
        }
    }
    
    private var shouldShowToolbar: Bool {
        switch placement {
        case .menuBar:
            return CapabilityDomain.Visual.hasMenuBar
        case .sidebar:
            return CapabilityDomain.Visual.prefersSidebar
        case .tabBar:
            return CapabilityDomain.Visual.prefersTabBar
        case .automatic:
            return true
        }
    }
    
    enum ToolbarPlacement {
        case menuBar
        case sidebar
        case tabBar
        case automatic
    }
}

// MARK: - Adaptive Modal Presentation
extension View {
    func adaptiveModal<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            if CapabilityDomain.Layout.prefersFullWidthSheets {
                content()
            } else {
                content()
                    .frame(minWidth: 400, minHeight: 300)
            }
        }
    }
}

// MARK: - Platform-Aware Spacing

// MARK: - Adaptive Density Container
struct AdaptiveDensityContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environment(\.platformDensity, CapabilityDomain.Density.uiDensity)
    }
}

// MARK: - Environment Key for Platform Density
private struct PlatformDensityKey: EnvironmentKey {
    static let defaultValue: UIDensity = CapabilityDomain.Density.uiDensity
}

extension EnvironmentValues {
    var platformDensity: UIDensity {
        get { self[PlatformDensityKey.self] }
        set { self[PlatformDensityKey.self] = newValue }
    }
}

// MARK: - Adaptive Grid
struct AdaptiveGrid<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            content
        }
    }
    
    private var columns: [GridItem] {
        let count: Int
        switch CapabilityDomain.Density.uiDensity {
        case .minimal:
            count = 1
        case .standard:
            count = 2
        case .comfortable:
            count = 3
        case .dense:
            count = 4
        }
        return Array(repeating: GridItem(.flexible()), count: count)
    }
    
    private var spacing: CGFloat {
        CapabilityDomain.Density.paddingScale * 12
    }
}

// MARK: - Adaptive Text Size
extension View {
    func adaptiveTextSize(_ baseSize: CGFloat) -> some View {
        let scaledSize: CGFloat
        switch CapabilityDomain.Density.uiDensity {
        case .minimal:
            scaledSize = baseSize * 0.9
        case .standard:
            scaledSize = baseSize
        case .comfortable:
            scaledSize = baseSize * 1.1
        case .dense:
            scaledSize = baseSize * 0.95
        }
        return self.font(.system(size: scaledSize))
    }
}

// MARK: - Platform-Specific Gesture Modifiers
extension View {
    /// Add platform-appropriate tap/click handling
    func adaptiveTapGesture(action: @escaping () -> Void) -> some View {
        if CapabilityDomain.Interaction.hasPointerPrecision {
            return AnyView(
                self.onTapGesture(perform: action)
                    .platformHoverEffect()
            )
        } else {
            return AnyView(
                self.onTapGesture(perform: action)
            )
        }
    }
    
    /// Add platform-appropriate long-press handling
    func adaptiveLongPress(action: @escaping () -> Void) -> some View {
        let minimumDuration: Double = Platform.isWatch ? 0.3 : 0.5
        return self.onLongPressGesture(minimumDuration: minimumDuration, perform: action)
    }
}

// MARK: - Adaptive Spacing
struct AdaptiveVStack<Content: View>: View {
    let alignment: HorizontalAlignment
    let content: Content
    
    init(alignment: HorizontalAlignment = .center, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: platformSpacing) {
            content
        }
    }
    
    private var platformSpacing: CGFloat {
        CapabilityDomain.Density.paddingScale * 12
    }
}

struct AdaptiveHStack<Content: View>: View {
    let alignment: VerticalAlignment
    let content: Content
    
    init(alignment: VerticalAlignment = .center, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.content = content()
    }
    
    var body: some View {
        HStack(alignment: alignment, spacing: platformSpacing) {
            content
        }
    }
    
    private var platformSpacing: CGFloat {
        CapabilityDomain.Density.paddingScale * 12
    }
}

// MARK: - Platform Feature Flags
struct PlatformFeature {
    /// Check if a feature should be enabled on current platform
    static func isEnabled(_ feature: Feature) -> Bool {
        switch feature {
        case .multiWindow:
            return CapabilityDomain.Interaction.supportsMultipleWindows
        case .keyboardShortcuts:
            return CapabilityDomain.Interaction.supportsKeyboardShortcuts
        case .dragAndDrop:
            return CapabilityDomain.Interaction.supportsCrossPlatformDragDrop
        case .hoverEffects:
            return CapabilityDomain.Interaction.supportsHover
        case .contextMenus:
            return CapabilityDomain.Interaction.supportsRichContextMenus
        case .floatingPanels:
            return CapabilityDomain.Layout.supportsFloatingPanels
        case .splitView:
            return CapabilityDomain.Layout.supportsMultiPane
        case .menuBar:
            return CapabilityDomain.Visual.hasMenuBar
        }
    }
    
    enum Feature {
        case multiWindow
        case keyboardShortcuts
        case dragAndDrop
        case hoverEffects
        case contextMenus
        case floatingPanels
        case splitView
        case menuBar
    }
}

// MARK: - Conditional View Helper
extension View {
    @ViewBuilder
    func platformConditional<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
