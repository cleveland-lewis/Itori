#if os(macOS)
    import SwiftUI

    struct AddCourseSheet: View {
        @Environment(\.dismiss) private var dismiss
        @EnvironmentObject private var coursesStore: CoursesStore

        @State private var title: String = ""
        @State private var code: String = ""
        @State private var semesterId: UUID? = nil

        var body: some View {
            VStack {
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(NSLocalizedString("ui.new.course", value: "New Course", comment: "New Course"))
                            .font(.title3.bold())

                        TextField("Biology 101", text: $title)
                        TextField("e.g. BIO 101", text: $code)

                        Text(NSLocalizedString("ui.semester", value: "Semester", comment: "Semester"))
                        SemesterPicker(selectedSemesterId: $semesterId)
                            .environmentObject(coursesStore)

                        HStack {
                            Spacer()
                            Button(NSLocalizedString("ui.button.cancel", value: "Cancel", comment: "Cancel")) {
                                dismiss()
                            }
                            Button(NSLocalizedString("ui.button.save", value: "Save", comment: "Save")) {
                                guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                guard let semId = semesterId ?? coursesStore.currentSemesterId,
                                      let sem = coursesStore.semesters.first(where: { $0.id == semId }) else { return }

                                coursesStore.addCourse(title: title, code: code, to: sem)
                                dismiss()
                            }
                            .buttonStyle(.glassBlueProminent)
                        }
                        .font(.callout)
                    }
                }
                .padding(DesignSystem.Layout.padding.window)
            }
            .frame(width: 420)
        }
    }
#endif
