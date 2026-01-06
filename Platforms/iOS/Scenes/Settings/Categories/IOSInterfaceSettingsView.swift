import SwiftUI
#if os(iOS)

struct IOSInterfaceSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @EnvironmentObject var preferences: AppPreferences
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.layoutMetrics) private var layoutMetrics
    
    @State private var glassIntensity: Double = 0.5
    
    private var isPad: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        List {
            // Appearance Section
            Section {
                // Appearance Style Picker
                Picker(NSLocalizedString("settings.interface.appearance.picker", value: "Appearance", comment: "Appearance picker"), selection: $settings.interfaceStyle) {
                    ForEach(InterfaceStyle.allCases.filter { $0 != .auto }) { style in
                        Text(style.label).tag(style)
                    }
                }
                .onChange(of: settings.interfaceStyle) { _, _ in
                    settings.save()
                }
                .prefsListRowInsets()
                
            } header: {
                Text(NSLocalizedString("settings.interface.appearance.header", value: "Appearance", comment: "Appearance header"))
            }
            
            // Tab Bar Pages Section
            Section {
                ForEach(availableTabs, id: \.self) { tab in
                    let isStarred = settings.starredTabs.contains(tab)
                    let isRequired = TabRegistry.definition(for: tab)?.isSystemRequired ?? false
                    let canToggleOff = isStarred && !isRequired
                    let isFlashcardsDisabled = tab == .flashcards && !settings.enableFlashcards
                    let canToggleOn = !isStarred && settings.starredTabs.count < 5 && !isFlashcardsDisabled
                    
                    Toggle(isOn: Binding(
                        get: { isStarred },
                        set: { newValue in
                            toggleTab(tab, enabled: newValue)
                        }
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 18))
                                .frame(width: 28)
                                .foregroundColor(isRequired ? .green : .primary)
                            Text(tab.title)
                            if isRequired {
                                Spacer()
                                Text(NSLocalizedString("settings.interface.tabs.required", value: "Required", comment: "Required tab label"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(isFlashcardsDisabled || (isStarred && isRequired) || (!isStarred && !canToggleOn))
                    .listRowInsets(EdgeInsets(
                        top: layoutMetrics.listRowVerticalPadding,
                        leading: 16,
                        bottom: layoutMetrics.listRowVerticalPadding,
                        trailing: 16
                    ))
                }
            } header: {
                Text(NSLocalizedString("settings.interface.tabs.header", value: "Tab Bar Pages", comment: "Tab bar pages header"))
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("settings.interface.tabs.footer", value: "Select up to 5 pages to show in the tab bar. All pages remain accessible via the menu.", comment: "Tab bar pages footer"))
                    if settings.starredTabs.count >= 5 {
                        Text(NSLocalizedString("settings.interface.tabs.max_reached", value: "Maximum of 5 tabs reached. Disable a tab to enable another.", comment: "Tab bar max reached"))
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Layout Section
            Section {
                if isPad {
                    Toggle(isOn: $settings.showSidebarByDefaultStorage) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("settings.interface.layout.sidebar", value: "Show Sidebar", comment: "Show sidebar"))
                            Text(NSLocalizedString("settings.interface.layout.sidebar.detail", value: "Always display the navigation sidebar on iPad", comment: "Show sidebar detail"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: settings.showSidebarByDefaultStorage) { _, _ in
                        settings.save()
                    }
                    .listRowInsets(EdgeInsets(
                        top: layoutMetrics.listRowVerticalPadding,
                        leading: 16,
                        bottom: layoutMetrics.listRowVerticalPadding,
                        trailing: 16
                    ))
                }
                
                Toggle(isOn: $settings.compactModeStorage) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.interface.layout.compact", value: "Compact Mode", comment: "Compact mode"))
                        Text(NSLocalizedString("settings.interface.layout.compact.detail", value: "Use denser layout with less spacing", comment: "Compact mode detail"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: settings.compactModeStorage) { _, _ in
                    settings.save()
                }
                .listRowInsets(EdgeInsets(
                    top: layoutMetrics.listRowVerticalPadding,
                    leading: 16,
                    bottom: layoutMetrics.listRowVerticalPadding,
                    trailing: 16
                ))
                
                Toggle(isOn: $settings.largeTapTargetsStorage) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.interface.layout.large_taps", value: "Large Tap Targets", comment: "Large tap targets"))
                        Text(NSLocalizedString("settings.interface.layout.large_taps.detail", value: "Increase button and control sizes for easier tapping", comment: "Large tap targets detail"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: settings.largeTapTargetsStorage) { _, _ in
                    settings.save()
                }
                .listRowInsets(EdgeInsets(
                    top: layoutMetrics.listRowVerticalPadding,
                    leading: 16,
                    bottom: layoutMetrics.listRowVerticalPadding,
                    trailing: 16
                ))
            } header: {
                Text(NSLocalizedString("settings.interface.layout.header", value: "Layout", comment: "Layout header"))
            } footer: {
                Text(NSLocalizedString("settings.interface.layout.footer", value: "Layout changes apply immediately to all screens.", comment: "Layout footer"))
            }
            
            // Interactions Section
            Section {
                Toggle(isOn: $settings.showAnimationsStorage) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.interface.interactions.animations", value: "Show Animations", comment: "Show animations"))
                        Text(NSLocalizedString("settings.interface.interactions.animations.detail", value: "Enable optional UI animations (still respects Reduce Motion)", comment: "Show animations detail"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: settings.showAnimationsStorage) { _, _ in
                    settings.save()
                }
                .prefsListRowInsets()
                
                Toggle(isOn: $settings.enableHapticsStorage) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.interface.interactions.haptics", value: "Enable Haptic Feedback", comment: "Enable haptics"))
                        Text(NSLocalizedString("settings.interface.interactions.haptics.detail", value: "Provide tactile feedback for interactions", comment: "Enable haptics detail"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: settings.enableHapticsStorage) { _, _ in
                    settings.save()
                }
                .prefsListRowInsets()
            } header: {
                Text(NSLocalizedString("settings.interface.interactions.header", value: "Interactions", comment: "Interactions header"))
            } footer: {
                Text(NSLocalizedString("settings.interface.interactions.footer", value: "Haptic feedback and animations respect accessibility settings.", comment: "Interactions footer"))
            }

            Section {
                Toggle(isOn: Binding(
                    get: { settings.hideGPAOnDashboard },
                    set: { settings.hideGPAOnDashboard = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("settings.dashboard.hide_gpa", value: "Hide GPA on dashboard", comment: "Hide GPA toggle label"))
                        Text(NSLocalizedString("settings.dashboard.hide_gpa.detail", value: "Remove GPA labels from the dashboard grade charts.", comment: "Hide GPA detail"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: settings.hideGPAOnDashboard) { _, _ in
                    settings.save()
                }
            } header: {
                Text(NSLocalizedString("settings.dashboard.section_title", value: "Dashboard", comment: "Dashboard section header"))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(NSLocalizedString("settings.category.interface", comment: "Interface"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            glassIntensity = preferences.glassIntensity
        }
    }
    
    private var availableTabs: [RootTab] {
        TabRegistry.allTabs.map { $0.id }
    }
    
    private func toggleTab(_ tab: RootTab, enabled: Bool) {
        guard let definition = TabRegistry.definition(for: tab) else { return }
        
        // Prevent disabling required tabs
        if definition.isSystemRequired && !enabled {
            return
        }
        
        var currentTabs = settings.starredTabs
        
        if enabled {
            // Add tab (if not at limit)
            if currentTabs.count < 5 && !currentTabs.contains(tab) {
                currentTabs.append(tab)
            }
        } else {
            // Remove tab (if not required)
            if !definition.isSystemRequired {
                currentTabs.removeAll { $0 == tab }
            }
        }
        
        settings.starredTabs = currentTabs
        settings.save()
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        IOSInterfaceSettingsView()
            .environmentObject(AppSettingsModel.shared)
    }
}
#endif
#endif
