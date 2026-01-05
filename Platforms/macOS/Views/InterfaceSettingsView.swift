#if os(macOS)
import SwiftUI

struct InterfaceSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @EnvironmentObject var preferences: AppPreferences
    @State private var glassIntensity: Double = 0.5

    enum AccentColorOption: String, CaseIterable, Identifiable {
        case blue = "Blue"
        case purple = "Purple"
        case pink = "Pink"
        case red = "Red"
        case orange = "Orange"
        case yellow = "Yellow"
        case green = "Green"
        case teal = "Teal"

        var id: String { rawValue }

        var color: Color {
            switch self {
            case .blue: return .blue
            case .purple: return .purple
            case .pink: return .pink
            case .red: return .red
            case .orange: return .orange
            case .yellow: return .yellow
            case .green: return .green
            case .teal: return .teal
            }
        }
    }

    @State private var selectedAccentColor: AccentColorOption = .blue

    var body: some View {
        Form {
            Section("Accessibility") {
                Toggle(NSLocalizedString("settings.toggle.reduce.motion", value: "Reduce Motion", comment: "Reduce Motion"), isOn: $preferences.reduceMotion)
                    .onChange(of: preferences.reduceMotion) { _, _ in /* AppStorage persists */ }

                Toggle(NSLocalizedString("settings.toggle.increase.contrast", value: "Increase Contrast", comment: "Increase Contrast"), isOn: $preferences.highContrast)
                    .onChange(of: preferences.highContrast) { _, _ in /* AppStorage persists */ }

                Toggle(NSLocalizedString("settings.toggle.reduce.transparency", value: "Reduce Transparency", comment: "Reduce Transparency"), isOn: $preferences.reduceTransparency)
                    .onChange(of: preferences.reduceTransparency) { _, _ in /* AppStorage persists */ }
            }

            Section("Appearance") {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                    Text(NSLocalizedString("settings.material.intensity", value: "Material Intensity", comment: "Material Intensity"))

                    HStack {
                        Text(NSLocalizedString("settings.low", value: "Low", comment: "Low"))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)

                        Slider(value: $glassIntensity, in: 0...1)
                            .onChange(of: glassIntensity) { _, newValue in
                                preferences.glassIntensity = newValue
                                settings.glassIntensity = newValue
                                settings.save()
                            }

                        Text(NSLocalizedString("settings.high", value: "High", comment: "High"))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Picker("Accent Color", selection: $preferences.accentColorName) {
                    ForEach(AppPreferences.AppAccent.allCases) { accent in
                        HStack {
                            Circle().fill(accent.color).frame(width: 12, height: 12)
                            Text(accent.rawValue)
                        }
                        .tag(accent.rawValue)
                    }
                }
                .onChange(of: preferences.accentColorName) { _, newValue in
                    // AppStorage in AppPreferences already persists; UI will read preferences.currentAccentColor
                }
            }

            Section("Layout") {
                Picker("Tab Style", selection: Binding(
                    get: { preferences.tabBarMode },
                    set: { newValue in
                        preferences.tabBarMode = newValue
                    }
                )) {
                    Text(NSLocalizedString("settings.icons", value: "Icons", comment: "Icons")).tag(TabBarMode.iconsOnly)
                    Text(NSLocalizedString("settings.text", value: "Text", comment: "Text")).tag(TabBarMode.textOnly)
                    Text(NSLocalizedString("settings.icons.text", value: "Icons & Text", comment: "Icons & Text")).tag(TabBarMode.iconsAndText)
                }

                Toggle(NSLocalizedString("settings.toggle.sidebar", value: "Sidebar", comment: "Sidebar"), isOn: $settings.showSidebarByDefault)
                    .onChange(of: settings.showSidebarByDefault) { _, _ in settings.save() }

                Toggle(NSLocalizedString("settings.toggle.compact.density", value: "Compact Density", comment: "Compact Density"), isOn: $settings.compactMode)
                    .onChange(of: settings.compactMode) { _, _ in settings.save() }
            }

            Section {
                Toggle(NSLocalizedString("settings.toggle.show.animations", value: "Show Animations", comment: "Show Animations"), isOn: $settings.showAnimations)
                    .onChange(of: settings.showAnimations) { _, _ in settings.save() }

                VStack(alignment: .leading, spacing: 4) {
                    Toggle(NSLocalizedString("settings.toggle.enable.haptic.feedback", value: "Enable Haptic Feedback", comment: "Enable Haptic Feedback"), isOn: $settings.enableHaptics)
                        .onChange(of: settings.enableHaptics) { _, _ in settings.save() }
                    
                    if preferences.reduceMotion {
                        Text(NSLocalizedString("settings.haptic.feedback.is.disabled.when", value: "Haptic feedback is disabled when Reduce Motion is enabled", comment: "Haptic feedback is disabled when Reduce Motion is ..."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(NSLocalizedString("settings.toggle.show.tooltips", value: "Show Tooltips", comment: "Show Tooltips"), isOn: $settings.showTooltips)
                    .onChange(of: settings.showTooltips) { _, _ in settings.save() }
            } header: {
                Text(NSLocalizedString("settings.interactions", value: "Interactions", comment: "Interactions"))
            } footer: {
                Text(NSLocalizedString("settings.haptic.feedback.respects.accessibility.settings", value: "Haptic feedback respects accessibility settings", comment: "Haptic feedback respects accessibility settings"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Interface")
        .onAppear {
            // Load current values
            glassIntensity = preferences.glassIntensity
            selectedAccentColor = AccentColorOption(rawValue: preferences.accentColorName) ?? .blue
        }
    }
}

#if !DISABLE_PREVIEWS
#if !DISABLE_PREVIEWS
#Preview {
    InterfaceSettingsView()
        .environmentObject(AppSettingsModel.shared)
        .environmentObject(AppPreferences())
        .frame(width: 500, height: 600)
}
#endif
#endif
#endif
