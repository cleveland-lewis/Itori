import SwiftUI

#if os(macOS)
    struct AppPageScaffold<Content: View>: View {
        @EnvironmentObject private var settings: AppSettingsModel
        @Environment(\.appLayout) private var appLayout

        let title: String
        let quickActions: [QuickAction]
        let onQuickAction: (QuickAction) -> Void
        let onSettings: () -> Void
        let content: Content

        private let buttonSpacing: CGFloat = 10
        private let collapseWidth: CGFloat = 720
        private let headerButtonSize: CGFloat = 40
        private let energyPillHeight: CGFloat = 32
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
                    top: appLayout.overlayTopInset + measuredHeaderHeight,
                    leading: 0,
                    bottom: 0,
                    trailing: appLayout.overlayTrailingInset + (isCompact ? 44 : (44 + buttonSpacing + 44))
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
                Spacer()
            }
            .padding(.top, appLayout.overlayTopInset)
            .padding(.horizontal, appLayout.overlayTrailingInset)
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
            .padding(.top, appLayout.overlayTopInset)
            .padding(.trailing, appLayout.overlayTrailingInset)
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
                    Button(NSLocalizedString(
                        "ui.button.open.settings",
                        value: "Open Settings",
                        comment: "Open Settings"
                    )) {
                        onSettings()
                    }
                    .keyboardShortcut(",", modifiers: [.command])
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: headerButtonSize, height: headerButtonSize)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.itariLiquid)
            .accessibilityLabelWithTooltip("Quick add and settings")
            .conditionalHelp("Quick add and settings")
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
                    .frame(width: headerButtonSize, height: headerButtonSize)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.itariLiquid)
            .accessibilityLabelWithTooltip("Quick add")
            .conditionalHelp("Quick add")
            .accessibilityHint("Opens quick add actions")
            .accessibilityIdentifier("Overlay.QuickAdd")
        }

        private var energyIndicator: some View {
            Group {
                if settings.showEnergyPanel && settings.energySelectionConfirmed {
                    Menu {
                        Button(NSLocalizedString("ui.button.high", value: "High", comment: "High")) { setEnergy("High")
                        }
                        Button(NSLocalizedString("ui.button.medium", value: "Medium", comment: "Medium")) {
                            setEnergy("Medium")
                        }
                        Button(NSLocalizedString("ui.button.low", value: "Low", comment: "Low")) { setEnergy("Low") }
                    } label: {
                        Text(verbatim: "Energy: \(settings.defaultEnergyLevel)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .frame(height: energyPillHeight)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .buttonStyle(.itariLiquid)
                    .accessibilityLabelWithTooltip("Energy level")
                    .conditionalHelp("Energy level")
                }
            }
        }

        private func setEnergy(_ level: String) {
            settings.defaultEnergyLevel = level
            settings.energySelectionConfirmed = true
            settings.save()
            PlannerSyncCoordinator.shared.requestRecompute(
                assignmentsStore: AssignmentsStore.shared,
                plannerStore: PlannerStore.shared,
                settings: settings
            )
        }

        private var settingsButton: some View {
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: headerButtonSize, height: headerButtonSize)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.itariLiquid)
            .accessibilityLabelWithTooltip("Settings")
            .conditionalHelp("Settings")
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
