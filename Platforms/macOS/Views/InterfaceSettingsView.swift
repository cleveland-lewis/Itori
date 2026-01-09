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
                case .blue: .blue
                case .purple: .purple
                case .pink: .pink
                case .red: .red
                case .orange: .orange
                case .yellow: .yellow
                case .green: .green
                case .teal: .teal
                }
            }
        }

        @State private var selectedAccentColor: AccentColorOption = .blue

        var body: some View {
            Form {
                Section("Appearance") {
                    Picker("Accent Color", selection: $preferences.accentColorName) {
                        ForEach(AppPreferences.AppAccent.allCases) { accent in
                            HStack {
                                Circle().fill(accent.color).frame(width: 12, height: 12)
                                Text(accent.rawValue)
                            }
                            .tag(accent.rawValue)
                        }
                    }
                    .onChange(of: preferences.accentColorName) { _, _ in
                        // AppStorage in AppPreferences already persists; UI will read preferences.currentAccentColor
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Interface")
            .onAppear {
                // Load current values
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
