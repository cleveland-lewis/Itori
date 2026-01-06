#if os(iOS)
import SwiftUI

struct IOSPracticeTestTakingView: View {
    let test: PracticeTest
    @ObservedObject var store: PracticeTestStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentQuestionIndex = 0
    @State private var userAnswers: [UUID: String] = [:]
    @State private var questionStartTimes: [UUID: Date] = [:]
    @State private var showingSubmitConfirmation = false
    
    private var currentQuestion: PracticeQuestion? {
        guard currentQuestionIndex < test.questions.count else { return nil }
        return test.questions[currentQuestionIndex]
    }
    
    private var progress: Double {
        guard !test.questions.isEmpty else { return 0 }
        return Double(userAnswers.count) / Double(test.questions.count)
    }
    
    private let choiceLabels = ["A", "B", "C", "D", "E"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress header
                progressHeader
                
                // Question content
                if let question = currentQuestion {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            questionHeader(question)
                            questionPrompt(question)
                            answerChoices(question)
                            navigationButtons
                        }
                        .padding(20)
                    }
                } else {
                    emptyState
                }
            }
            .navigationTitle(test.courseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("iospracticetesttaking.button.exit", value: "Exit", comment: "Exit")) {
                        dismiss()
                        store.clearCurrentTest()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("iospracticetesttaking.button.submit", value: "Submit", comment: "Submit")) {
                        showingSubmitConfirmation = true
                    }
                    .disabled(userAnswers.count < test.questions.count)
                    .fontWeight(.semibold)
                }
            }
            .alert("Submit Test?", isPresented: $showingSubmitConfirmation) {
                Button(NSLocalizedString("Cancel", value: "Cancel", comment: ""), role: .cancel) { }
                Button(NSLocalizedString("Submit", value: "Submit", comment: ""), role: .destructive) {
                    submitTest()
                }
            } message: {
                if userAnswers.count < test.questions.count {
                    Text(verbatim: "You have answered \(userAnswers.count) out of \(test.questions.count) questions. Unanswered questions will be marked incorrect.")
                } else {
                    Text(NSLocalizedString("iospracticetesttaking.are.you.sure.you.want", value: "Are you sure you want to submit? You cannot change your answers after submission.", comment: "Are you sure you want to submit? You cannot change..."))
                }
            }
        }
        .onAppear {
            if test.status == .ready {
                store.startTest(test.id)
            }
            initializeQuestionTimers()
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text(verbatim: "Question \(currentQuestionIndex + 1) of \(test.questions.count)")
                    .font(.subheadline.bold())
                
                Spacer()
                
                Text(verbatim: "\(userAnswers.count) answered")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: progress)
                .tint(.blue)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
    
    // MARK: - Question Components
    
    private func questionHeader(_ question: PracticeQuestion) -> some View {
        HStack {
            if let bloomsLevel = question.bloomsLevel {
                Text(bloomsLevel)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.15))
                    )
                    .foregroundStyle(.blue)
            }
            
            Spacer()
            
            if userAnswers[question.id] != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
        }
    }
    
    private func questionPrompt(_ question: PracticeQuestion) -> some View {
        Text(question.prompt)
            .font(.title3)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func answerChoices(_ question: PracticeQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(Array((question.options ?? []).enumerated()), id: \.offset) { index, option in
                answerButton(
                    letter: choiceLabels[safe: index] ?? "\(index + 1)",
                    text: option,
                    isSelected: userAnswers[question.id] == option,
                    action: {
                        saveAnswer(for: question, answer: option)
                    }
                )
            }
        }
    }
    
    private func answerButton(letter: String, text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                // Letter badge
                Text(letter)
                    .font(.headline.bold())
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.blue : Color(uiColor: .systemGray5))
                    )
                    .foregroundStyle(isSelected ? .white : .primary)
                
                // Answer text
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Navigation
    
    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentQuestionIndex > 0 {
                Button {
                    withAnimation {
                        currentQuestionIndex -= 1
                    }
                } label: {
                    Label(NSLocalizedString("iospracticetesttaking.label.previous", value: "Previous", comment: "Previous"), systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        )
                }
                .buttonStyle(.plain)
            }
            
            if currentQuestionIndex < test.questions.count - 1 {
                Button {
                    withAnimation {
                        currentQuestionIndex += 1
                    }
                } label: {
                    Label(NSLocalizedString("iospracticetesttaking.label.next", value: "Next", comment: "Next"), systemImage: "chevron.right")
                        .labelStyle(.titleAndIcon)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.blue)
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(NSLocalizedString("iospracticetesttaking.no.questions.available", value: "No questions available", comment: "No questions available"))
                .font(.title3.bold())
            Text(NSLocalizedString("iospracticetesttaking.something.went.wrong.loading.the.test", value: "Something went wrong loading the test", comment: "Something went wrong loading the test"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    
    private func saveAnswer(for question: PracticeQuestion, answer: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            userAnswers[question.id] = answer
        }
        
        let timeSpent = questionStartTimes[question.id].map { Date().timeIntervalSince($0) }
        store.answerQuestion(
            testId: test.id,
            questionId: question.id,
            answer: answer,
            timeSpent: timeSpent
        )
        
        // Reset timer for this question
        questionStartTimes[question.id] = Date()
        
        // Auto-advance to next question after a brief delay
        if currentQuestionIndex < test.questions.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    currentQuestionIndex += 1
                }
            }
        }
    }
    
    private func initializeQuestionTimers() {
        for question in test.questions {
            if questionStartTimes[question.id] == nil {
                questionStartTimes[question.id] = Date()
            }
        }
    }
    
    private func submitTest() {
        store.submitTest(test.id)
        dismiss()
    }
}

// Array safe subscript extension
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#endif
