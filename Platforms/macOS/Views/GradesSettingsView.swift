#if os(macOS)
    import SwiftUI

    struct GradesSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel

        var body: some View {
            Form {
                Section {
                    Picker("Grade Display Format", selection: Binding(
                        get: { settings.gradeScale },
                        set: { newValue in
                            settings.gradeScale = newValue
                            settings.save()
                        }
                    )) {
                        ForEach(GradeScale.allCases) { scale in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(scale.label)
                                Text(scale.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(scale)
                        }
                    }
                    .pickerStyle(.radioGroup)
                } header: {
                    Text("Grade Scale")
                } footer: {
                    Text("Choose how grades are displayed throughout the app")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Grades")
        }
    }

    #if !DISABLE_PREVIEWS
        #Preview {
            GradesSettingsView()
                .environmentObject(AppSettingsModel.shared)
                .frame(width: 500, height: 400)
        }
    #endif
#endif
