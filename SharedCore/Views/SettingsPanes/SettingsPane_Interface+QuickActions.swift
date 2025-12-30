import SwiftUI

extension SettingsPane_Interface {
    var quickActionsEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(DesignSystem.Typography.subHeader)
            Text("Configure the quick actions shown under the + button in the top-left of the app.")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.secondary)

            QuickActionsEditorView()
        }
    }
}

struct QuickActionsEditorView: View {
    @EnvironmentObject private var settings: AppSettingsModel
    @State private var available = QuickAction.allCases
    private let maxSelection = 6

    var body: some View {
        VStack {
            List {
                ForEach(available, id: \.self) { action in
                    let isSelected = settings.quickActions.contains(action)
                    let isAtLimit = settings.quickActions.count >= maxSelection
                    HStack {
                        Image(systemName: action.systemImage)
                        Text(action.title)
                        Spacer()
                        Toggle("", isOn: Binding(get: { isSelected }, set: { new in
                            guard new || isSelected else { return }
                            var cur = settings.quickActions
                            if new {
                                if !cur.contains(action), cur.count < maxSelection { cur.append(action) }
                            } else {
                                cur.removeAll { $0 == action }
                            }
                            settings.quickActions = cur
                            settings.save()
                        }))
                        .labelsHidden()
                        .disabled(!isSelected && isAtLimit)
                    }
                }
                .onMove(perform: move)
            }
            .frame(height: 260)

            HStack {
                Button("Restore Defaults") {
                    settings.quickActions = QuickAction.defaultSelection
                    settings.save()
                }
                .onChange(of: settings.quickActions) { _, _ in settings.save() }
                Button("Add Custom Action") {
                    // placeholder: custom quick action creation UI may be added
                }
                Spacer()
            }
            Text("Select up to \(maxSelection) actions.")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.secondary)
        }
    }

    private func move(from: IndexSet, to: Int) {
        var cur = settings.quickActions
        cur.move(fromOffsets: from, toOffset: to)
        settings.quickActions = cur
        settings.save()
    }
}
