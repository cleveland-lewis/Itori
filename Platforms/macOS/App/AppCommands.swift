#if os(macOS)
    import SwiftUI

    struct AppCommands: Commands {
        var body: some Commands {
            CommandMenu("Add") {
                Button(NSLocalizedString("ui.button.add.grade", value: "Add Grade", comment: "Add Grade")) {
                    NotificationCenter.default.post(name: .addGradeRequested, object: nil)
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Button(NSLocalizedString(
                    "ui.button.add.assignment",
                    value: "Add Assignment",
                    comment: "Add Assignment"
                )) {
                    NotificationCenter.default.post(name: .addAssignmentRequested, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])

                Button(NSLocalizedString(
                    "ui.button.add.work.session",
                    value: "Add Work Session",
                    comment: "Add Work Session"
                )) {
                    NotificationCenter.default.post(name: .addWorkSessionRequested, object: nil)
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
            }
        }
    }

    struct SettingsCommands: Commands {
        let showSettings: () -> Void

        var body: some Commands {
            CommandGroup(replacing: .appSettings) {
                Button(NSLocalizedString("Preferences…", value: "Preferences…", comment: ""), action: showSettings)
                    .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
#endif
