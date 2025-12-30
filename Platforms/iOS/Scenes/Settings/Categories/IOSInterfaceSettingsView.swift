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
            // Accessibility Section
            Section {
                Toggle(isOn: $preferences.reduceMotion) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reduce Motion")
                        Text("Minimize animations throughout the app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: preferences.reduceMotion) { _, newValue in
                    settings.reduceMotionStorage = newValue
                    settings.save()
                }
                .prefsListRowInsets()
                
                Toggle(isOn: $preferences.highContrast) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Increase Contrast")
                        Text("Strengthen borders and text contrast")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: preferences.highContrast) { _, newValue in
                    settings.increaseContrastStorage = newValue
                    settings.save()
                }
                .prefsListRowInsets()
                
                Toggle(isOn: $preferences.reduceTransparency) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reduce Transparency")
                        Text("Replace translucent backgrounds with opaque colors")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: preferences.reduceTransparency) { _, newValue in
                    settings.reduceTransparencyStorage = newValue
                    settings.save()
                }
                .prefsListRowInsets()
            } header: {
                Text("Accessibility")
            } footer: {
                Text("These settings help improve readability and reduce visual complexity.")
            }
            
            // Appearance Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Material Intensity")
                    
                    HStack {
                        Text("Low")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $glassIntensity, in: 0...1)
                            .onChange(of: glassIntensity) { _, newValue in
                                preferences.glassIntensity = newValue
                                settings.glassIntensityStorage = newValue
                                settings.save()
                            }
                        
                        Text("High")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Adjust the visual intensity of glass and material effects")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                .prefsListRowInsets()
            } header: {
                Text("Appearance")
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
                                Text("Required")
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
                Text("Tab Bar Pages")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select up to 5 pages to show in the tab bar. All pages remain accessible via the menu.")
                    if settings.starredTabs.count >= 5 {
                        Text("Maximum of 5 tabs reached. Disable a tab to enable another.")
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Layout Section
            Section {
                if isPad {
                    Toggle(isOn: $settings.showSidebarByDefaultStorage) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Show Sidebar")
                            Text("Always display the navigation sidebar on iPad")
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
                        Text("Compact Mode")
                        Text("Use denser layout with less spacing")
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
                        Text("Large Tap Targets")
                        Text("Increase button and control sizes for easier tapping")
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
                Text("Layout")
            } footer: {
                Text("Layout changes apply immediately to all screens.")
            }
            
            // Interactions Section
            Section {
                Toggle(isOn: $settings.showAnimationsStorage) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Show Animations")
                        Text("Enable optional UI animations (still respects Reduce Motion)")
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
                        Text("Enable Haptic Feedback")
                        Text("Provide tactile feedback for interactions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: settings.enableHapticsStorage) { _, _ in
                    settings.save()
                }
                .prefsListRowInsets()
            } header: {
                Text("Interactions")
            } footer: {
                Text("Haptic feedback and animations respect accessibility settings.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Interface")
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
