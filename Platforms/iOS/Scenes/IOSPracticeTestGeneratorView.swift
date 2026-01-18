#if os(iOS)
    import SwiftUI

    struct IOSPracticeTestGeneratorView: View {
        @Environment(\.dismiss) private var dismiss
        @EnvironmentObject private var coursesStore: CoursesStore
        @ObservedObject var store: PracticeTestStore

        @State private var selectedCourse: Course?
        @State private var selectedModule: CourseOutlineNode?
        @State private var selectedTopics: [String] = []
        @State private var customTopic: String = ""
        @State private var difficulty: PracticeTestDifficulty = .medium
        @State private var questionCount: Int = 10

        private let questionCountOptions = [5, 10, 15, 20, 25]

        var body: some View {
            NavigationStack {
                Form {
                    courseSelectionSection
                    moduleSelectionSection
                    topicsSection
                    settingsSection
                    infoSection
                }
                .navigationTitle("Generate Practice Test")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(NSLocalizedString(
                            "iospracticetestgenerator.button.cancel",
                            value: "Cancel",
                            comment: "Cancel"
                        )) {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(NSLocalizedString(
                            "iospracticetestgenerator.button.generate",
                            value: "Generate",
                            comment: "Generate"
                        )) {
                            generateTest()
                        }
                        .disabled(!canGenerate)
                        .fontWeight(.semibold)
                    }
                }
            }
        }

        // MARK: - Course Selection

        private var courseSelectionSection: some View {
            Section {
                if coursesStore.courses.isEmpty {
                    Text(NSLocalizedString(
                        "iospracticetestgenerator.no.courses.available.please.add.a.course.first",
                        value: "No courses available. Please add a course first.",
                        comment: "No courses available. Please add a course first."
                    ))
                    .foregroundStyle(.secondary)
                    .font(.callout)
                } else {
                    Picker("Course", selection: $selectedCourse) {
                        Text(NSLocalizedString(
                            "iospracticetestgenerator.select.a.course",
                            value: "Select a course",
                            comment: "Select a course"
                        )).tag(nil as Course?)
                        ForEach(coursesStore.courses) { course in
                            Text(course.code.isEmpty ? course.title : course.code).tag(course as Course?)
                        }
                    }
                    .onChange(of: selectedCourse) { _, _ in
                        selectedModule = nil
                    }
                }
            } header: {
                Text(NSLocalizedString("iospracticetestgenerator.course", value: "Course", comment: "Course"))
            }
        }

        // MARK: - Module Selection

        private var moduleSelectionSection: some View {
            Section {
                if let course = selectedCourse {
                    let modules = availableModules(for: course)

                    if modules.isEmpty {
                        Text(NSLocalizedString(
                            "iospracticetestgenerator.no_modules",
                            value: "No modules available for this course.",
                            comment: "No modules available"
                        ))
                        .foregroundStyle(.secondary)
                        .font(.callout)
                    } else {
                        Picker("Module", selection: $selectedModule) {
                            Text(NSLocalizedString(
                                "iospracticetestgenerator.select.a.module",
                                value: "Select a module",
                                comment: "Select a module"
                            )).tag(nil as CourseOutlineNode?)
                            ForEach(modules) { module in
                                Text(module.title).tag(module as CourseOutlineNode?)
                            }
                        }
                    }
                } else {
                    Text(NSLocalizedString(
                        "iospracticetestgenerator.select_course_first",
                        value: "Select a course first",
                        comment: "Select course first"
                    ))
                    .foregroundStyle(.secondary)
                    .font(.callout)
                }
            } header: {
                Text(NSLocalizedString("iospracticetestgenerator.module", value: "Module", comment: "Module"))
            } footer: {
                if selectedModule != nil {
                    Text(NSLocalizedString(
                        "iospracticetestgenerator.module.help",
                        value: "Questions will be generated from this module's content",
                        comment: "Module help"
                    ))
                }
            }
        }

        private func availableModules(for course: Course) -> [CourseOutlineNode] {
            coursesStore.outlineNodes
                .filter { $0.courseId == course.id && $0.type == .module }
                .sorted { $0.sortIndex < $1.sortIndex }
        }

        // MARK: - Topics

        private var topicsSection: some View {
            Section {
                if !selectedTopics.isEmpty {
                    ForEach(selectedTopics, id: \.self) { topic in
                        HStack {
                            Text(topic)
                            Spacer()
                            Button {
                                selectedTopics.removeAll { $0 == topic }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .accessibilityHidden(true)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove \(topic)")
                            .accessibilityHint("Removes this topic from the test")
                        }
                    }
                }

                HStack {
                    TextField("Add topic", text: $customTopic)
                        .onSubmit(addCustomTopic)

                    Button(NSLocalizedString("iospracticetestgenerator.button.add", value: "Add", comment: "Add")) {
                        addCustomTopic()
                    }
                    .disabled(customTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } header: {
                Text(NSLocalizedString(
                    "iospracticetestgenerator.topics.optional",
                    value: "Topics (Optional)",
                    comment: "Topics (Optional)"
                ))
            } footer: {
                Text(NSLocalizedString(
                    "iospracticetestgenerator.specify.topics.to.focus.on",
                    value: "Specify topics to focus on, or leave blank for general practice",
                    comment: "Specify topics to focus on, or leave blank for gen..."
                ))
            }
        }

        private func addCustomTopic() {
            let trimmed = customTopic.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !selectedTopics.contains(trimmed) else { return }
            selectedTopics.append(trimmed)
            customTopic = ""
        }

        // MARK: - Settings

        private var settingsSection: some View {
            Section {
                // Difficulty
                Picker("Difficulty", selection: $difficulty) {
                    ForEach(PracticeTestDifficulty.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }

                // Question Count
                Picker("Number of Questions", selection: $questionCount) {
                    ForEach(questionCountOptions, id: \.self) { count in
                        Text(verbatim: "\(count)").tag(count)
                    }
                }
            } header: {
                Text(NSLocalizedString(
                    "iospracticetestgenerator.test.settings",
                    value: "Test Settings",
                    comment: "Test Settings"
                ))
            }
        }

        // MARK: - Info

        private var infoSection: some View {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        NSLocalizedString(
                            "iospracticetestgenerator.label.multiple.choice.only",
                            value: "Multiple Choice Only",
                            comment: "Multiple Choice Only"
                        ),
                        systemImage: "list.bullet.circle"
                    )
                    .font(.subheadline.bold())
                    Text(
                        verbatim: "Test will contain \(questionCount) multiple-choice questions with 5 answer choices (A-E)"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text(NSLocalizedString("iospracticetestgenerator.format", value: "Format", comment: "Format"))
            }
        }

        private var canGenerate: Bool {
            selectedCourse != nil && selectedModule != nil
        }

        private func generateTest() {
            guard let course = selectedCourse,
                  let module = selectedModule else { return }

            let request = PracticeTestRequest(
                courseId: course.id,
                courseName: course.code.isEmpty ? course.title : course.code,
                moduleId: module.id,
                moduleName: module.title,
                topics: selectedTopics,
                difficulty: difficulty,
                questionCount: questionCount,
                includeMultipleChoice: true,
                includeShortAnswer: false,
                includeExplanation: false
            )

            Task {
                await store.generateTest(request: request)
            }

            dismiss()
        }
    }

#endif
