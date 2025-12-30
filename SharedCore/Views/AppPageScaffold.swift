import SwiftUI

#if os(macOS)
struct AppPageScaffold<Content: View>: View {
    @EnvironmentObject private var settings: AppSettingsModel
    let title: String
    let quickActions: [QuickAction]
    let onQuickAction: (QuickAction) -> Void
    let onSettings: () -> Void
    let content: Content

    private let overlayTopInset: CGFloat = 16
    private let overlayTrailingInset: CGFloat = 24
    private let buttonSpacing: CGFloat = 10
    private let collapseWidth: CGFloat = 720
    @State private var measuredHeaderHeight: CGFloat = 56

    init(
        title: String,
        quickActions: [QuickAction],
        onQuickAction: @escaping (QuickAction) -> Void,
        onSettings: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.quickActions = quickActions
        self.onQuickAction = onQuickAction
        self.onSettings = onSettings
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < collapseWidth
            let overlayInsets = EdgeInsets(
                top: overlayTopInset + measuredHeaderHeight,
                leading: 0,
                bottom: 0,
                trailing: overlayTrailingInset + (isCompact ? 44 : (44 + buttonSpacing + 44))
            )

            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    header
                    content
                }

                overlayControls(isCompact: isCompact)
                shortcutsLayer
            }
            .environment(\.overlayInsets, overlayInsets)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)
                .accessibilityIdentifier("Overlay.Title")
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.top, overlayTopInset)
        .padding(.horizontal, overlayTrailingInset)
        .background(HeightReporter())
        .onPreferenceChange(HeaderHeightKey.self) { height in
            if height > 0, measuredHeaderHeight != height {
                measuredHeaderHeight = height
            }
        }
    }

    private func overlayControls(isCompact: Bool) -> some View {
        HStack(spacing: buttonSpacing) {
            if isCompact {
                energyIndicator
                overflowMenu
            } else {
                energyIndicator
                quickAddButton
                settingsButton
            }
        }
        .padding(.top, overlayTopInset)
        .padding(.trailing, overlayTrailingInset)
        .frame(maxWidth: .infinity, alignment: .topTrailing)
    }

    private var overflowMenu: some View {
        Menu {
            Section("Quick Add") {
                ForEach(quickActions) { action in
                    Button(action.title) {
                        onQuickAction(action)
                    }
                    .keyboardShortcut("n", modifiers: [.command])
                }
            }
            Section("Settings") {
                Button("Open Settings") {
                    onSettings()
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Quick add and settings")
        .accessibilityHint("Opens quick actions and settings")
        .accessibilityIdentifier("Overlay.Overflow")
    }

    private var quickAddButton: some View {
        Menu {
            ForEach(quickActions) { action in
                Button(action.title) {
                    onQuickAction(action)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Quick add")
        .accessibilityHint("Opens quick add actions")
        .accessibilityIdentifier("Overlay.QuickAdd")
    }

    private var energyIndicator: some View {
        Group {
            if settings.showEnergyPanel && settings.energySelectionConfirmed {
                Menu {
                    Button("High") { setEnergy("High") }
                    Button("Medium") { setEnergy("Medium") }
                    Button("Low") { setEnergy("Low") }
                } label: {
                    Text("Energy: \(settings.defaultEnergyLevel)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Energy level")
            }
        }
    }

    private func setEnergy(_ level: String) {
        settings.defaultEnergyLevel = level
        settings.energySelectionConfirmed = true
        settings.save()
    }

    private var settingsButton: some View {
        Button(action: onSettings) {
            Image(systemName: "gearshape")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
        .accessibilityHint("Opens settings")
        .accessibilityIdentifier("Overlay.Settings")
        .keyboardShortcut(",", modifiers: [.command])
    }

    private var shortcutsLayer: some View {
        Group {
            if let primaryQuickAction = quickActions.first {
                Button(primaryQuickAction.title) {
                    onQuickAction(primaryQuickAction)
                }
                .keyboardShortcut("n", modifiers: [.command])
                .opacity(0)
                .accessibilityHidden(true)
            }
        }
        .frame(width: 0, height: 0)
    }
}

private struct HeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct HeightReporter: View {
    var body: some View {
        GeometryReader { proxy in
            Color.clear.preference(key: HeaderHeightKey.self, value: proxy.size.height)
        }
    }
}
#endif
