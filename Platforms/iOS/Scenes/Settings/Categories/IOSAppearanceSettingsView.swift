#if os(iOS)
import SwiftUI
import Combine

struct IOSAppearanceSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @Environment(\.colorScheme) private var colorScheme
    
    private var interfaceStyle: InterfaceStyle {
        get {
            InterfaceStyle(rawValue: settings.interfaceStyleRaw) ?? .system
        }
        nonmutating set {
            settings.interfaceStyleRaw = newValue.rawValue
        }
    }
    
    var body: some View {
        List {
            Section {
                Picker(selection: Binding(
                    get: { interfaceStyle },
                    set: { newValue in
                        settings.objectWillChange.send()
                        interfaceStyle = newValue
                        settings.save()
                    }
                )) {
                    ForEach([InterfaceStyle.system, .light, .dark], id: \.self) { style in
                        Text(styleLabel(style)).tag(style)
                    }
                } label: {
                    Text(NSLocalizedString("settings.appearance.theme", comment: "Theme"))
                }
                .pickerStyle(.segmented)
            } header: {
                Text(NSLocalizedString("settings.appearance.theme.header", comment: "Appearance"))
            }
            
            Section {
                Toggle(isOn: Binding(
                    get: { settings.enableGlassEffectsStorage },
                    set: { newValue in
                        settings.objectWillChange.send()
                        settings.enableGlassEffectsStorage = newValue
                        settings.save()
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.appearance.glass_effects", comment: "Glass Effects"))
                        Text(NSLocalizedString("settings.appearance.glass_effects.detail", comment: "Use translucent backgrounds and blur"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $settings.showAnimationsStorage) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.appearance.animations", comment: "Show Animations"))
                        Text(NSLocalizedString("settings.appearance.animations.detail", comment: "Enable smooth transitions and effects"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: settings.showAnimationsStorage) { _, _ in
                    settings.save()
                }
            } header: {
                Text(NSLocalizedString("settings.appearance.effects.header", comment: "Effects"))
            }
            
            Section {
                Picker(selection: Binding(
                    get: { CardRadius(rawValue: settings.cardRadiusRaw) ?? .medium },
                    set: { newValue in
                        settings.objectWillChange.send()
                        settings.cardRadiusRaw = newValue.rawValue
                        settings.save()
                    }
                )) {
                    ForEach(CardRadius.allCases, id: \.self) { radius in
                        Text(radius.label).tag(radius)
                    }
                } label: {
                    Text(NSLocalizedString("settings.appearance.card_radius", comment: "Card Corner Radius"))
                }
            } header: {
                Text(NSLocalizedString("settings.appearance.style.header", comment: "Style"))
            }

            Section {
                Picker(selection: Binding(
                    get: { settings.accentColorChoice },
                    set: { newValue in
                        settings.objectWillChange.send()
                        settings.accentColorChoice = newValue
                        settings.save()
                    }
                )) {
                    ForEach(AppAccentColor.allCases) { accent in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(accent.color)
                                .frame(width: 14, height: 14)
                            Text(accent.label)
                        }
                        .tag(accent)
                    }
                } label: {
                    Text(NSLocalizedString("settings.appearance.accent", value: "Accent Color", comment: "Accent color"))
                }
                .pickerStyle(.menu)

                Toggle(isOn: Binding(
                    get: { settings.isCustomAccentEnabled },
                    set: { newValue in
                        settings.objectWillChange.send()
                        settings.isCustomAccentEnabled = newValue
                        settings.save()
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.appearance.accent.custom.toggle", value: "Enable custom accent color", comment: "Enable custom accent color"))
                        Text(NSLocalizedString("settings.appearance.accent.custom.detail", value: "Overrides the built-in palette.", comment: "Custom accent color detail"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                ColorPicker(
                    NSLocalizedString("settings.appearance.accent.custom.picker", value: "Custom accent tint", comment: "Custom accent tint"),
                    selection: Binding(
                        get: { settings.customAccentColor },
                        set: { settings.customAccentColor = $0; settings.save() }
                    )
                )
                .disabled(!settings.isCustomAccentEnabled)
                .foregroundStyle(settings.isCustomAccentEnabled ? .primary : .secondary)
            } header: {
                Text(NSLocalizedString("settings.appearance.accent.header", value: "Accent", comment: "Accent section header"))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(NSLocalizedString("settings.category.appearance", comment: "Appearance"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: settings.showAnimationsStorage) { _, _ in
            settings.objectWillChange.send()
        }
    }
    
    private func styleLabel(_ style: InterfaceStyle) -> String {
        switch style {
        case .system:
            return NSLocalizedString("settings.appearance.theme.system", comment: "System")
        case .light:
            return NSLocalizedString("settings.appearance.theme.light", comment: "Light")
        case .dark:
            return NSLocalizedString("settings.appearance.theme.dark", comment: "Dark")
        case .auto:
            return NSLocalizedString("settings.appearance.theme.auto", comment: "Auto")
        }
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        IOSAppearanceSettingsView()
            .environmentObject(AppSettingsModel.shared)
    }
}
#endif
#endif
