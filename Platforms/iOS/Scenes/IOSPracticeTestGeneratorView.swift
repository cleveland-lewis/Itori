#if os(iOS)
import SwiftUI

struct IOSPracticeTestGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coursesStore: CoursesStore
    @ObservedObject var store: PracticeTestStore
    
    @State private var selectedCourse: Course?
    @State private var selectedTopics: [String] = []
    @State private var customTopic: String = ""
    @State private var difficulty: PracticeTestDifficulty = .medium
    @State private var questionCount: Int = 10
    
    private let questionCountOptions = [5, 10, 15, 20, 25]
    
    var body: some View {
        NavigationStack {
            Form {
                courseSelectionSection
                topicsSection
                settingsSection
                infoSection
            }
            .navigationTitle("Generate Practice Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("iospracticetestgenerator.button.cancel", value: "Cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("iospracticetestgenerator.button.generate", value: "Generate", comment: "Generate")) {
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
                Text(NSLocalizedString("iospracticetestgenerator.no.courses.available.please.add.a.course.first", value: "No courses available. Please add a course first.", comment: "No courses available. Please add a course first."))
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                Picker("Course", selection: $selectedCourse) {
                    Text(NSLocalizedString("iospracticetestgenerator.select.a.course", value: "Select a course", comment: "Select a course")).tag(nil as Course?)
                    ForEach(coursesStore.courses) { course in
                        Text(course.code.isEmpty ? course.title : course.code).tag(course as Course?)
                    }
                }
            }
        } header: {
            Text(NSLocalizedString("iospracticetestgenerator.course", value: "Course", comment: "Course"))
        }
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
                        }
                        .buttonStyle(.plain)
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
            Text(NSLocalizedString("iospracticetestgenerator.topics.optional", value: "Topics (Optional)", comment: "Topics (Optional)"))
        } footer: {
            Text(NSLocalizedString("iospracticetestgenerator.specify.topics.to.focus.on", value: "Specify topics to focus on, or leave blank for general practice", comment: "Specify topics to focus on, or leave blank for gen..."))
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
            Text(NSLocalizedString("iospracticetestgenerator.test.settings", value: "Test Settings", comment: "Test Settings"))
        }
    }
    
    // MARK: - Info
    
    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label(NSLocalizedString("iospracticetestgenerator.label.multiple.choice.only", value: "Multiple Choice Only", comment: "Multiple Choice Only"), systemImage: "list.bullet.circle")
                    .font(.subheadline.bold())
                Text(verbatim: "Test will contain \(questionCount) multiple-choice questions with 5 answer choices (A-E)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text(NSLocalizedString("iospracticetestgenerator.format", value: "Format", comment: "Format"))
        }
    }
    
    private var canGenerate: Bool {
        selectedCourse != nil
    }
    
    private func generateTest() {
        guard let course = selectedCourse else { return }
        
        let request = PracticeTestRequest(
            courseId: course.id,
            courseName: course.code.isEmpty ? course.title : course.code,
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
