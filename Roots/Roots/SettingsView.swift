import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    // design tokens
    @State private var selectedMaterial: DesignMaterial = .regular

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("General")) {
                    NavigationLink(destination: EmptyView().navigationTitle("Appearance")) {
                        HStack {
                            DesignSystem.Icons.settings
                            Text("Appearance")
                        }
                    }
                    NavigationLink(destination: EmptyView().navigationTitle("Notifications")) {
                        Label("Notifications", systemImage: "bell")
                    }
                }

                Section(header: Text("Account")) {
                    NavigationLink(destination: EmptyView().navigationTitle("Profile")) {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
                }

                Section(header: Text("Advanced")) {
                    NavigationLink(destination: DebugSettingsView(selectedMaterial: $selectedMaterial)) {
                        Label("Developer", systemImage: "hammer")
                    }
                }

                Section(header: Text("Design")) {
                    Picker("Material", selection: $selectedMaterial) {
                        ForEach(DesignSystem.materials, id: \.id) { token in
                            Text(token.name).tag(token as DesignMaterial)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            #if os(iOS)
            #if os(iOS)
            .listStyle(.insetGrouped)
#else
            .listStyle(.plain)
#endif
#else
            .listStyle(.plain)
#endif
            .navigationTitle("Settings")
            .background(DesignSystem.background(for: colorScheme))
        }
    }
}

private struct DebugSettingsView: View {
    @Binding var selectedMaterial: DesignMaterial

    var body: some View {
        Form {
            Toggle("Enable verbose logging", isOn: .constant(false))
            Button("Reset demo data") { }

            Section(header: Text("Design debug")) {
                HStack {
                    Text("Selected material")
                    Spacer()
                    Text(selectedMaterial.name)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Developer")
    }
}

#Preview {
    SettingsView()
}