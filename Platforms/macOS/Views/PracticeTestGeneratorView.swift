#if os(macOS)
    import SwiftUI

    struct PracticeTestGeneratorView: View {
        @Environment(\.dismiss) private var dismiss
        @EnvironmentObject private var appModel: AppModel
        @EnvironmentObject private var coursesStore: CoursesStore
        @ObservedObject var store: PracticeTestStore

        @State private var selectedCourse: Course?
        @State private var selectedModule: CourseOutlineNode?
        @State private var selectedTopics: [String] = []
        @State private var customTopic: String = ""
        @State private var difficulty: PracticeTestDifficulty = .medium
        @State private var questionCount: Int = 10
        @State private var includeMultipleChoice = true
        @State private var includeShortAnswer = true
        @State private var includeExplanation = false

        private let questionCountOptions = [5, 10, 15, 20]

        var body: some View {
            VStack(spacing: 0) {
                headerView

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        courseSelectionSection
                        moduleSelectionSection
                        topicsSection
                        settingsSection
                        questionTypesSection
                    }
                    .padding(24)
                }

                bottomBar
            }
            .frame(width: 600, height: 700)
        }

        // MARK: - Header

        private var headerView: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("practice.generator.title", comment: "Generate Practice Test"))
                        .font(.title2.bold())
                    Text(NSLocalizedString(
                        "practice.generator.subtitle",
                        comment: "Configure your practice test parameters"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.ultraThinMaterial)
        }

        // MARK: - Course Selection

        private var courseSelectionSection: some View {
            VStack(alignment: .leading, spacing: 12) {
                Label(
                    NSLocalizedString("practice.generator.section.course", comment: "Course"),
                    systemImage: "book.closed"
                )
                .font(.headline)

                if coursesStore.courses.isEmpty {
                    Text(NSLocalizedString(
                        "practice.generator.course.no_courses",
                        comment: "No courses available. Please add a course first."
                    ))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                } else {
                    Picker(
                        NSLocalizedString("practice.generator.course.select", comment: "Select Course"),
                        selection: $selectedCourse
                    ) {
                        Text(NSLocalizedString("practice.generator.course.select", comment: "Select a course"))
                            .tag(nil as Course?)
                        ForEach(coursesStore.courses) { course in
                            Text(course.code).tag(course as Course?)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: selectedCourse) { _, _ in
                        // Reset module selection when course changes
                        selectedModule = nil
                    }
                }
            }
        }

        // MARK: - Module Selection

        private var moduleSelectionSection: some View {
            VStack(alignment: .leading, spacing: 12) {
                Label(
                    NSLocalizedString("practice.generator.section.module", comment: "Module"),
                    systemImage: "book.pages"
                )
                .font(.headline)

                if let course = selectedCourse {
                    let modules = availableModules(for: course)

                    if modules.isEmpty {
                        Text(NSLocalizedString(
                            "practice.generator.module.no_modules",
                            comment: "No modules available for this course."
                        ))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    } else {
                        Picker(
                            NSLocalizedString("practice.generator.module.select", comment: "Select Module"),
                            selection: $selectedModule
                        ) {
                            Text(NSLocalizedString("practice.generator.module.select", comment: "Select a module"))
                                .tag(nil as CourseOutlineNode?)
                            ForEach(modules) { module in
                                Text(module.title).tag(module as CourseOutlineNode?)
                            }
                        }
                        .labelsHidden()

                        Text(NSLocalizedString(
                            "practice.generator.module.help",
                            comment: "Select the module to generate questions from"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                } else {
                    Text(NSLocalizedString(
                        "practice.generator.module.select_course_first",
                        comment: "Select a course first"
                    ))
                    .foregroundStyle(.secondary)
                    .font(.caption)
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
            VStack(alignment: .leading, spacing: 12) {
                Label(
                    NSLocalizedString("practice.generator.section.topics", comment: "Topics (Optional)"),
                    systemImage: "tag"
                )
                .font(.headline)

                Text(NSLocalizedString(
                    "practice.generator.topics.help",
                    comment: "Specify topics to focus on, or leave blank for general practice"
                ))
                .font(.caption)
                .foregroundStyle(.secondary)

                if !selectedTopics.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedTopics, id: \.self) { topic in
                                topicChip(topic)
                            }
                        }
                    }
                }

                HStack {
                    TextField(
                        NSLocalizedString("practice.generator.topics.add_field", comment: "Add topic"),
                        text: $customTopic
                    )
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addCustomTopic)

                    Button(NSLocalizedString("practice.generator.topics.add_button", comment: "Add")) {
                        addCustomTopic()
                    }
                    .disabled(customTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }

        private func topicChip(_ topic: String) -> some View {
            HStack(spacing: 4) {
                Text(topic)
                    .font(.caption)

                Button {
                    selectedTopics.removeAll { $0 == topic }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.blue.opacity(0.2))
            .clipShape(Capsule())
        }

        private func addCustomTopic() {
            let trimmed = customTopic.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !selectedTopics.contains(trimmed) else { return }
            selectedTopics.append(trimmed)
            customTopic = ""
        }

        // MARK: - Settings

        private var settingsSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                Label(
                    NSLocalizedString("practice.generator.section.settings", comment: "Settings"),
                    systemImage: "slider.horizontal.3"
                )
                .font(.headline)

                // Difficulty
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("practice.generator.difficulty.label", comment: "Difficulty"))
                        .font(.subheadline.bold())

                    Picker(
                        NSLocalizedString("practice.generator.difficulty.label", comment: "Difficulty"),
                        selection: $difficulty
                    ) {
                        ForEach(PracticeTestDifficulty.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Question Count
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(NSLocalizedString(
                            "practice.generator.question_count.label",
                            comment: "Number of Questions"
                        ))
                        .font(.subheadline.bold())
                        Spacer()
                        Text(verbatim: "\(questionCount)")
                            .foregroundStyle(.secondary)
                    }

                    Picker(
                        NSLocalizedString("practice.generator.question_count.label", comment: "Question Count"),
                        selection: $questionCount
                    ) {
                        ForEach(questionCountOptions, id: \.self) { count in
                            Text(verbatim: "\(count)").tag(count)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }

        // MARK: - Question Types

        private var questionTypesSection: some View {
            VStack(alignment: .leading, spacing: 12) {
                Label(
                    NSLocalizedString("practice.generator.section.question_types", comment: "Question Types"),
                    systemImage: "list.bullet.circle"
                )
                .font(.headline)

                Text(NSLocalizedString("practice.generator.types.help", comment: "Select at least one question type"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle(isOn: $includeMultipleChoice) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("practice.generator.types.multiple_choice", comment: "Multiple Choice"))
                            .font(.subheadline)
                        Text(NSLocalizedString(
                            "practice.generator.types.multiple_choice_desc",
                            comment: "Select from 4 options"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $includeShortAnswer) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("practice.generator.types.short_answer", comment: "Short Answer"))
                            .font(.subheadline)
                        Text(NSLocalizedString(
                            "practice.generator.types.short_answer_desc",
                            comment: "Brief written responses"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $includeExplanation) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("practice.generator.types.explanation", comment: "Explanation"))
                            .font(.subheadline)
                        Text(NSLocalizedString(
                            "practice.generator.types.explanation_desc",
                            comment: "Detailed explanations with examples"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }

        // MARK: - Bottom Bar

        private var bottomBar: some View {
            HStack {
                Button(NSLocalizedString("practice.action.cancel", comment: "Cancel")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(NSLocalizedString("practice.action.generate", comment: "Generate Test")) {
                    generateTest()
                }
                .buttonStyle(.itoriLiquidProminent)
                .disabled(!canGenerate)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(.ultraThinMaterial)
        }

        private var canGenerate: Bool {
            selectedCourse != nil &&
                selectedModule != nil &&
                (includeMultipleChoice || includeShortAnswer || includeExplanation)
        }

        private func generateTest() {
            guard let course = selectedCourse,
                  let module = selectedModule else { return }

            let request = PracticeTestRequest(
                courseId: course.id,
                courseName: course.code,
                moduleId: module.id,
                moduleName: module.title,
                topics: selectedTopics,
                difficulty: difficulty,
                questionCount: questionCount,
                includeMultipleChoice: includeMultipleChoice,
                includeShortAnswer: includeShortAnswer,
                includeExplanation: includeExplanation
            )

            Task {
                await store.generateTest(request: request)
            }

            dismiss()
        }
    }

#endif
