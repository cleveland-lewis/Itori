import SwiftUI

struct SettingsPane_Appearance: View {
    @EnvironmentObject private var settings: AppSettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Accent color", selection: $settings.accentColorChoice) {
                        ForEach(AppAccentColor.allCases) { accent in
                            HStack(spacing: DesignSystem.Layout.spacing.small) {
                                Circle()
                                    .fill(accent.color)
                                    .frame(width: 14, height: 14)
                                Text(accent.label)
                            }
                            .tag(accent)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: settings.accentColorChoice) { _, _ in settings.save() }
                    Toggle(NSLocalizedString("settings.toggle.enable.custom.accent.color", value: "Enable custom accent color", comment: "Enable custom accent color"), isOn: $settings.isCustomAccentEnabled)
                        .onChange(of: settings.isCustomAccentEnabled) { _, _ in settings.save() }

                    ColorPicker(
                        "Custom accent tint",
                        selection: Binding(
                            get: { settings.customAccentColor },
                            set: { settings.customAccentColor = $0; settings.save() }
                        )
                    )
                    .disabled(!settings.isCustomAccentEnabled)
                    .foregroundStyle(settings.isCustomAccentEnabled ? .primary : .secondary)

                    Text(NSLocalizedString("settings.custom.colors.override.the.builtin.palette", value: "Custom colors override the built-in palette.", comment: "Custom colors override the built-in palette."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } label: {
                Label(NSLocalizedString("settings.label.accent", value: "Accent", comment: "Accent"), systemImage: "paintpalette")
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Interface style", selection: $settings.interfaceStyle) {
                        ForEach(InterfaceStyle.allCases) { style in
                            Text(style.label).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: settings.interfaceStyle) { _, _ in settings.save() }

                    Text(NSLocalizedString("settings.choose.how.itori.reacts.to", value: "Choose how Itori reacts to system appearance changes.", comment: "Choose how Itori reacts to system appearance chang..."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } label: {
                Label(NSLocalizedString("settings.label.interface", value: "Interface", comment: "Interface"), systemImage: "circle.lefthalf.fill")
            }

            Spacer()
        }
        .frame(maxWidth: 640)
    }
}
