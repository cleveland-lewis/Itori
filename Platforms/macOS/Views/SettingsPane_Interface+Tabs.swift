#if os(macOS)
import SwiftUI

extension SettingsPane_Interface {
    // Tab visibility editor
    var tabEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("settings.tab.bar.pages", value: "Tab Bar Pages", comment: "Tab Bar Pages"))
                .font(DesignSystem.Typography.subHeader)
            Text(NSLocalizedString("settings.choose.which.pages.appear.in", value: "Choose which pages appear in the floating tab bar and reorder them.", comment: "Choose which pages appear in the floating tab bar ..."))
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.secondary)

            TabEditorView()
        }
    }
}

struct TabEditorView: View {
    @EnvironmentObject private var settings: AppSettingsModel
    @State private var list: [RootTab] = []

    var body: some View {
        VStack {
            List {
                ForEach(list, id: \.self) { tab in
                    HStack {
                        Image(systemName: tab.systemImage)
                        Text(tab.title)
                        Spacer()
                        Toggle(NSLocalizedString("settings.toggle.", value: "", comment: ""), isOn: Binding(get: { settings.visibleTabs.contains(tab) }, set: { new in
                            var current = settings.visibleTabs
                            if new {
                                if !current.contains(tab) { current.append(tab) }
                            } else {
                                current.removeAll { $0 == tab }
                            }
                            settings.visibleTabs = current
                            settings.save()
                        }))
                        .labelsHidden()
                    }
                }
                .onMove(perform: move)
            }
            .frame(height: 280)

            HStack {
                Button(NSLocalizedString("settings.button.restore.defaults", value: "Restore Defaults", comment: "Restore Defaults")) {
                    settings.visibleTabs = [.dashboard, .calendar, .planner, .assignments, .courses, .grades]
                    settings.tabOrder = settings.visibleTabs
                }
                Spacer()
            }
        }
        .onAppear { list = RootTab.allCases }
    }

    private func move(from: IndexSet, to: Int) {
        var order = settings.tabOrder
        order.move(fromOffsets: from, toOffset: to)
        settings.tabOrder = order
    }
}
#endif
