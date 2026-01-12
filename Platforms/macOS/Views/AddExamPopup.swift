#if os(macOS)
    import SwiftUI
    import UniformTypeIdentifiers

    struct AddExamPopup: View {
        @EnvironmentObject var coursesStore: CoursesStore
        @EnvironmentObject var flashManager: FlashcardManager
        @Environment(\.dismiss) var dismiss

        @State private var title: String = ""
        @State private var selectedCourseId: UUID?
        @State private var date: Date = .init()
        @State private var weight: Double = 20

        @State private var uploadedURLs: [URL] = []
        @State private var showImporter = false

        @State private var generateStudyGuide: Bool = true
        @State private var createFlashcardDeck: Bool = true

        private var isSaveDisabled: Bool {
            title.trimmingCharacters(in: .whitespaces).isEmpty
        }

        var body: some View {
            StandardSheetContainer(
                title: "New Exam",
                primaryActionTitle: "Save",
                primaryAction: {
                    saveExam()
                    dismiss()
                },
                primaryActionDisabled: isSaveDisabled,
                onDismiss: { dismiss() }
            ) {
                VStack(alignment: .leading, spacing: 20) {
                    // Basic Info
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Exam Title", text: $title, prompt: Text("e.g., Midterm Exam"))
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 15))

                        Picker("Course", selection: Binding(
                            get: { selectedCourseId },
                            set: { selectedCourseId = $0 }
                        )) {
                            Text("Select course").tag(UUID?(nil))
                            ForEach(coursesStore.courses) { c in
                                Text(c.title).tag(Optional(c.id))
                            }
                        }
                        .font(.system(size: 13))

                        DatePicker("Date & Time", selection: $date)
                            .font(.system(size: 13))

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Grade Weight: \(Int(weight))%")
                                .font(.system(size: 13))
                            Slider(value: $weight, in: 0 ... 100, step: 1)
                        }
                    }

                    Divider()

                    // Study Materials
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Study Materials")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        Button {
                            showImporter = true
                        } label: {
                            HStack {
                                Image(systemName: "tray.and.arrow.up")
                                Text("Upload Syllabus / Practice Test")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .controlSize(.large)
                        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.pdf, .image]) { result in
                            switch result {
                            case let .success(url):
                                uploadedURLs.append(url)
                            case let .failure(err):
                                DebugLogger.log("import failed: \(err)")
                            }
                        }

                        if !uploadedURLs.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(uploadedURLs, id: \.self) { url in
                                    HStack {
                                        Image(systemName: "doc")
                                            .foregroundStyle(.secondary)
                                        Text(url.lastPathComponent)
                                            .font(.system(size: 13))
                                        Spacer()
                                        Button {
                                            uploadedURLs.removeAll { $0 == url }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding(8)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }

                        Toggle("Generate Study Guide", isOn: $generateStudyGuide)
                            .disabled(uploadedURLs.isEmpty)
                            .font(.system(size: 13))

                        Toggle("Create Flashcard Deck", isOn: $createFlashcardDeck)
                            .disabled(uploadedURLs.isEmpty)
                            .font(.system(size: 13))
                    }
                }
            }
        }

        private func saveExam() {
            let exam = Exam(title: title, courseId: selectedCourseId, dueDate: date, weightPercent: weight)

            if createFlashcardDeck {
                let deckTitle = "Study: \(title)"
                let deck = flashManager.createDeck(title: deckTitle, courseID: selectedCourseId)
                for url in uploadedURLs {
                    flashManager.addCard(
                        to: deck.id,
                        front: "From file: \(url.lastPathComponent)",
                        back: "Notes to be generated"
                    )
                }
            }

            if generateStudyGuide {
                let generatedTasks = PlannerService.shared.generateStudyBlocks(for: exam, fileURLs: uploadedURLs)
                for task in generatedTasks {
                    AssignmentsStore.shared.addTask(task)
                }
            }
        }
    }
#endif
