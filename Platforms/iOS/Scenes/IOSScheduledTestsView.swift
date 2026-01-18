#if os(iOS)
    import SwiftUI

    /// iOS view for scheduled practice tests with status badges
    struct IOSScheduledTestsView: View {
        @StateObject private var store = ScheduledTestsStore.shared
        @StateObject private var practiceStore = PracticeTestStore.shared
        @EnvironmentObject private var coursesStore: CoursesStore
        @State private var selectedTest: ScheduledPracticeTest?
        @State private var showingStartConfirmation = false
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(\.layoutMetrics) private var metrics

        private var isPad: Bool { horizontalSizeClass == .regular }

        private var upcomingTests: [ScheduledPracticeTest] {
            store.scheduledTests
                .filter { $0.status != .archived }
                .sorted { $0.scheduledAt < $1.scheduledAt }
        }

        var body: some View {
            NavigationStack {
                Group {
                    if upcomingTests.isEmpty {
                        emptyStateView
                    } else {
                        testListView
                    }
                }
                .navigationTitle("Scheduled Tests")
                .navigationBarTitleDisplayMode(.large)
                .alert("Start Test", isPresented: $showingStartConfirmation) {
                    Button(NSLocalizedString("Cancel", value: "Cancel", comment: ""), role: .cancel) {
                        selectedTest = nil
                    }
                    Button(NSLocalizedString("iosscheduledtests.button.start", value: "Start", comment: "Start")) {
                        if let test = selectedTest {
                            startTest(test)
                        }
                    }
                } message: {
                    if let test = selectedTest {
                        Text(verbatim: "Start '\(test.title)' now? This will create a new test attempt.")
                    }
                }
            }
        }

        private var emptyStateView: some View {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "calendar.badge.clock")
                    .font(.system(.largeTitle))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text(NSLocalizedString(
                        "iosscheduledtests.no.scheduled.tests",
                        value: "No Scheduled Tests",
                        comment: "No Scheduled Tests"
                    ))
                    .font(.title2.weight(.semibold))

                    Text(NSLocalizedString(
                        "iosscheduledtests.practice.tests.you.schedule.will.appear.here",
                        value: "Practice tests you schedule will appear here",
                        comment: "Practice tests you schedule will appear here"
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding()
        }

        private var testListView: some View {
            List {
                ForEach(upcomingTests) { test in
                    IOSScheduledTestRow(
                        test: test,
                        hasCompletedAttempt: store.hasCompletedAttempt(for: test.id),
                        onStart: {
                            selectedTest = test
                            showingStartConfirmation = true
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
        }

        private func startTest(_ scheduledTest: ScheduledPracticeTest) {
            // Record the attempt
            _ = store.startTest(scheduledTest: scheduledTest)

            // Create a practice test request
            Task {
                let topics = topicsForTest(scheduledTest)
                let request = PracticeTestRequest(
                    courseId: scheduledTest.courseId ?? UUID(),
                    courseName: scheduledTest.subject,
                    topics: topics,
                    difficulty: difficultyFromInt(scheduledTest.difficulty),
                    questionCount: max(10, scheduledTest.questionCount),
                    includeMultipleChoice: true,
                    includeShortAnswer: false,
                    includeExplanation: false
                )

                await practiceStore.generateTest(request: request)
            }

            selectedTest = nil
        }

        private func difficultyFromInt(_ level: Int) -> PracticeTestDifficulty {
            switch level {
            case 1 ... 2: .easy
            case 4 ... 5: .hard
            default: .medium
            }
        }

        private func topicsForTest(_ test: ScheduledPracticeTest) -> [String] {
            if !test.moduleIds.isEmpty {
                return coursesStore.outlineNodes
                    .filter { node in
                        guard test.moduleIds.contains(node.id) else { return false }
                        if let courseId = test.courseId {
                            return node.courseId == courseId
                        }
                        return true
                    }
                    .sorted { $0.sortIndex < $1.sortIndex }
                    .map(\.title)
            }
            if let unitName = test.unitName, !unitName.isEmpty {
                return [unitName]
            }
            return []
        }
    }

    /// Individual scheduled test row for iOS
    struct IOSScheduledTestRow: View {
        let test: ScheduledPracticeTest
        let hasCompletedAttempt: Bool
        let onStart: () -> Void

        @Environment(\.layoutMetrics) private var metrics

        private var currentStatus: ScheduledTestStatus {
            test.currentStatus(hasCompletedAttempt: hasCompletedAttempt)
        }

        private var canStart: Bool {
            currentStatus == .scheduled || currentStatus == .missed
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Title + Status Badge
                HStack(alignment: .top, spacing: 8) {
                    Text(test.title)
                        .font(.headline)
                        .lineLimit(2)

                    Spacer()

                    TestStatusBadge(status: currentStatus, isCompact: false)
                }

                // Metadata
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 12) {
                        Label(test.subject, systemImage: "book")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let unit = test.unitName {
                            Label(unit, systemImage: "folder")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 12) {
                        Label(test.scheduledAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let duration = test.estimatedMinutes {
                            Label(
                                NSLocalizedString(
                                    "iosscheduledtests.label.duration.min",
                                    value: "\(duration) min",
                                    comment: "\(duration) min"
                                ),
                                systemImage: "timer"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                // Action button
                if canStart {
                    Button(action: onStart) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text(currentStatus == .missed ? "Start Anyway" : "Start Test")
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.itoriLiquidProminent)
                    .controlSize(.small)
                }
            }
            .padding(metrics.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(statusBorderColor, lineWidth: 1.5)
            )
        }

        private var statusBorderColor: Color {
            switch currentStatus {
            case .scheduled:
                .blue.opacity(0.2)
            case .completed:
                .green.opacity(0.2)
            case .missed:
                .orange.opacity(0.2)
            case .archived:
                Color.secondary.opacity(0.1)
            }
        }
    }

#endif
