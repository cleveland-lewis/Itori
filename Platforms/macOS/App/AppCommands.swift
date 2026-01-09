#if os(macOS)
    import SwiftUI

    struct AppCommands: Commands {
        var body: some Commands {
            CommandMenu("Study") {
                Button(NSLocalizedString("ui.button.new.homework", value: "New Homework…", comment: "New Homework…")) {
                    AppModel.shared.isPresentingAddHomework = true
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])

                Button(NSLocalizedString("ui.button.new.exam", value: "New Exam…", comment: "New Exam…")) {
                    AppModel.shared.isPresentingAddExam = true
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Divider()

                Button(NSLocalizedString("ui.button.go.to.courses", value: "Go to Courses", comment: "Go to Courses")) {
                    AppModel.shared.selectedPage = .courses
                }
                .keyboardShortcut("1", modifiers: [.command, .option])

                Button(NSLocalizedString("ui.button.go.to.grades", value: "Go to Grades", comment: "Go to Grades")) {
                    AppModel.shared.selectedPage = .grades
                }
                .keyboardShortcut("2", modifiers: [.command, .option])
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
