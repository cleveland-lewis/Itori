import SwiftUI

#if os(iOS)

    struct IOSGradesSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel

        var body: some View {
            List {
                Section {
                    Picker("Grade Display Format", selection: Binding(
                        get: { settings.gradeScale },
                        set: { newValue in
                            settings.gradeScale = newValue
                            settings.save()
                        }
                    )) {
                        ForEach(GradeScale.allCases) { scale in
                            Text(scale.label).tag(scale)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Grade Scale")
                } footer: {
                    Text(settings.gradeScale.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(NSLocalizedString("settings.category.grades", value: "Grades", comment: "Grades"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    #if !DISABLE_PREVIEWS
        #Preview {
            NavigationStack {
                IOSGradesSettingsView()
                    .environmentObject(AppSettingsModel.shared)
            }
        }
    #endif
#endif
