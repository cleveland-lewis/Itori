#if os(macOS)
    import Combine
    import SwiftUI

    struct InterfaceSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel
        @EnvironmentObject var preferences: AppPreferences
        @State private var glassIntensity: Double = 0.5

        var body: some View {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $settings.interfaceStyle) {
                        ForEach(
                            [InterfaceStyle.system, InterfaceStyle.light, InterfaceStyle.dark],
                            id: \.self
                        ) { style in
                            Text(style.label).tag(style)
                        }
                    }
                    .onChange(of: settings.interfaceStyle) { _, newValue in
                        settings.save()
                        applyInterfaceStyle(newValue)
                    }

                    Picker("Accent Color", selection: Binding(
                        get: { settings.accentColorChoice },
                        set: { newValue in
                            settings.objectWillChange.send()
                            settings.accentColorChoice = newValue
                            settings.save()
                        }
                    )) {
                        ForEach(AppAccentColor.allCases.filter {
                            // Only show the commonly used colors
                            [.blue, .purple, .pink, .red, .orange, .yellow, .green, .aqua].contains($0)
                        }) { accent in
                            HStack {
                                Circle().fill(accent.color).frame(width: 12, height: 12)
                                Text(accent.label)
                            }
                            .tag(accent)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Interface")
            .onAppear {
                applyInterfaceStyle(settings.interfaceStyle)
            }
        }

        private func applyInterfaceStyle(_ style: InterfaceStyle) {
            #if os(macOS)
                let appearance: NSAppearance? = switch style {
                case .system, .auto:
                    nil // Use system default
                case .light:
                    NSAppearance(named: .aqua)
                case .dark:
                    NSAppearance(named: .darkAqua)
                }

                // Apply to all windows
                for window in NSApplication.shared.windows {
                    window.appearance = appearance
                }
            #endif
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
