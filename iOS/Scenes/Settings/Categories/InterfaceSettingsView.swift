import SwiftUI
#if os(iOS)

struct InterfaceSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @State private var selectedTabs: Set<RootTab> = []
    
    var body: some View {
        List {
            Section {
                ForEach(availableTabs, id: \.self) { tab in
                    Toggle(isOn: Binding(
                        get: { selectedTabs.contains(tab) },
                        set: { isSelected in
                            if isSelected {
                                if selectedTabs.count < 5 {
                                    selectedTabs.insert(tab)
                                }
                            } else {
                                selectedTabs.remove(tab)
                            }
                            saveSelection()
                        }
                    )) {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .disabled(!selectedTabs.contains(tab) && selectedTabs.count >= 5)
                }
            } header: {
                Text(NSLocalizedString("settings.interface.starred_tabs.header", comment: "Starred Tabs"))
            } footer: {
                Text(NSLocalizedString("settings.interface.starred_tabs.footer", comment: "Select up to 5 pages to show in the tab bar. All pages remain accessible via the menu."))
            }
            
            Section {
                Toggle(isOn: $settings.showSidebarByDefaultStorage) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.interface.show_sidebar", comment: "Show Sidebar"))
                        Text(NSLocalizedString("settings.interface.show_sidebar.detail", comment: "Always display the navigation sidebar on iPad"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $settings.compactModeStorage) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.interface.compact_mode", comment: "Compact Mode"))
                        Text(NSLocalizedString("settings.interface.compact_mode.detail", comment: "Use denser layout with less spacing"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(NSLocalizedString("settings.interface.layout.header", comment: "Layout"))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(NSLocalizedString("settings.category.interface", comment: "Interface"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedTabs = Set(settings.visibleTabs)
        }
    }
    
    private var availableTabs: [RootTab] {
        RootTab.allCases.filter { $0 != .settings }
    }
    
    private func saveSelection() {
        settings.visibleTabs = Array(selectedTabs).sorted { tab1, tab2 in
            availableTabs.firstIndex(of: tab1) ?? 0 < availableTabs.firstIndex(of: tab2) ?? 0
        }
    }
}

#Preview {
    NavigationStack {
        InterfaceSettingsView()
            .environmentObject(AppSettingsModel.shared)
    }
}
#endif
