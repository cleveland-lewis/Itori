#if os(iOS)
    import SwiftUI

    struct IOSPracticeTestResultsView: View {
        let test: PracticeTest
        @ObservedObject var store: PracticeTestStore
        @Environment(\.dismiss) private var dismiss
        @Environment(\.layoutMetrics) private var metrics

        @State private var expandedQuestionIds: Set<UUID> = []

        private var scorePercentage: Double {
            test.score ?? 0
        }

        private var scoreColor: Color {
            switch scorePercentage {
            case 0.9...:
                .green
            case 0.7 ..< 0.9:
                .blue
            case 0.5 ..< 0.7:
                .orange
            default:
                .red
            }
        }

        private let choiceLabels = ["A", "B", "C", "D", "E"]

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        scoreCard
                        statisticsSection
                        questionsReview
                    }
                    .padding(metrics.cardPadding)
                }
                .background(Color(uiColor: .systemGroupedBackground))
                .navigationTitle("Test Results")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(NSLocalizedString(
                            "iospracticetestresults.button.done",
                            value: "Done",
                            comment: "Done"
                        )) {
                            dismiss()
                            store.clearCurrentTest()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }

        // MARK: - Score Card

        private var scoreCard: some View {
            VStack(spacing: 16) {
                // Large score display
                VStack(spacing: 8) {
                    Text(verbatim: "\(Int(scorePercentage * 100))%")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(scoreColor)
                        .accessibilityAddTraits(.isHeader)

                    Text(verbatim: "\(test.correctCount) out of \(test.questions.count) correct")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                // Score interpretation
                Text(scoreInterpretation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }

        private var scoreInterpretation: String {
            switch scorePercentage {
            case 0.9...:
                "Excellent! You've mastered this material."
            case 0.8 ..< 0.9:
                "Great work! You have a strong understanding."
            case 0.7 ..< 0.8:
                "Good job! A few more topics to review."
            case 0.6 ..< 0.7:
                "Fair. Consider reviewing the material again."
            default:
                "Needs improvement. Review the explanations below."
            }
        }

        // MARK: - Statistics

        private var statisticsSection: some View {
            VStack(spacing: 12) {
                Text(NSLocalizedString(
                    "iospracticetestresults.test.details",
                    value: "Test Details",
                    comment: "Test Details"
                ))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 8) {
                    statisticRow(label: "Course", value: test.courseName)
                    statisticRow(label: "Difficulty", value: test.difficulty.rawValue)

                    if !test.topics.isEmpty {
                        statisticRow(label: "Topics", value: test.topics.joined(separator: ", "))
                    }

                    if let submittedAt = test.submittedAt {
                        statisticRow(label: "Completed", value: formattedDate(submittedAt))
                    }
                }
                .padding(metrics.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
            }
        }

        private func statisticRow(label: String, value: String) -> some View {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.subheadline.bold())
            }
        }

        // MARK: - Questions Review

        private var questionsReview: some View {
            VStack(spacing: 12) {
                Text(NSLocalizedString(
                    "iospracticetestresults.review.questions",
                    value: "Review Questions",
                    comment: "Review Questions"
                ))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(Array(test.questions.enumerated()), id: \.element.id) { index, question in
                    questionReviewCard(question: question, index: index + 1)
                }
            }
        }

        private func questionReviewCard(question: PracticeQuestion, index: Int) -> some View {
            let answer = test.answers[question.id]
            let isCorrect = answer?.isCorrect ?? false
            let isExpanded = expandedQuestionIds.contains(question.id)

            return VStack(alignment: .leading, spacing: 12) {
                // Header
                Button {
                    withAnimation {
                        if isExpanded {
                            expandedQuestionIds.remove(question.id)
                        } else {
                            expandedQuestionIds.insert(question.id)
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        // Question number badge
                        Text(verbatim: "\(index)")
                            .font(.headline.bold())
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(isCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            )
                            .foregroundStyle(isCorrect ? .green : .red)

                        // Status
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(isCorrect ? .green : .red)
                                    .font(.body)
                                    .accessibilityHidden(true)
                                Text(isCorrect ? "Correct" : "Incorrect")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(isCorrect ? .green : .red)
                            }

                            if let bloomsLevel = question.bloomsLevel {
                                Text(bloomsLevel)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .font(.caption)
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider()

                    // Question prompt
                    Text(question.prompt)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)

                    // Answer choices
                    VStack(spacing: 8) {
                        ForEach(Array((question.options ?? []).enumerated()), id: \.offset) { choiceIndex, choice in
                            answerChoiceReview(
                                letter: choiceLabels[safe: choiceIndex] ?? "\(choiceIndex + 1)",
                                text: choice,
                                isCorrect: choice == question.correctAnswer,
                                isUserAnswer: choice == answer?.userAnswer
                            )
                        }
                    }
                    .padding(.top, 8)

                    // Explanation
                    VStack(alignment: .leading, spacing: 8) {
                        Label(
                            NSLocalizedString(
                                "iospracticetestresults.label.explanation",
                                value: "Explanation",
                                comment: "Explanation"
                            ),
                            systemImage: "lightbulb"
                        )
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)

                        Text(question.explanation)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.blue.opacity(0.05))
                    )
                }
            }
            .padding(metrics.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }

        private func answerChoiceReview(
            letter: String,
            text: String,
            isCorrect: Bool,
            isUserAnswer: Bool
        ) -> some View {
            HStack(alignment: .top, spacing: 12) {
                // Letter badge
                Text(letter)
                    .font(.subheadline.bold())
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isCorrect ? Color.green.opacity(0.2) : Color(uiColor: .systemGray6))
                    )
                    .foregroundStyle(isCorrect ? .green : .primary)

                // Answer text
                HStack {
                    Text(text)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    // Indicators
                    HStack(spacing: 4) {
                        if isCorrect {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                        if isUserAnswer && !isCorrect {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        isCorrect ? Color.green.opacity(0.05) :
                            isUserAnswer ? Color.red.opacity(0.05) :
                            Color(uiColor: .systemGray6).opacity(0.3)
                    )
            )
        }

        // MARK: - Helpers

        private func formattedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }

    // Array safe subscript extension
    private extension Array {
        subscript(safe index: Int) -> Element? {
            indices.contains(index) ? self[index] : nil
        }
    }

#endif
