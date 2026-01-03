#if os(iOS)
import SwiftUI

/// iOS view for scheduled practice tests with status badges
struct IOSScheduledTestsView: View {
    @StateObject private var store = ScheduledTestsStore.shared
    @StateObject private var practiceStore = PracticeTestStore.shared
    @State private var selectedTest: ScheduledPracticeTest?
    @State private var showingStartConfirmation = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
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
                Button("Cancel", role: .cancel) {
                    selectedTest = nil
                }
                Button("Start") {
                    if let test = selectedTest {
                        startTest(test)
                    }
                }
            } message: {
                if let test = selectedTest {
                    Text("Start '\(test.title)' now? This will create a new test attempt.")
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("No Scheduled Tests")
                    .font(.title2.weight(.semibold))
                
                Text("Practice tests you schedule will appear here")
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
            let request = PracticeTestRequest(
                courseId: UUID(),
                courseName: scheduledTest.subject,
                topics: scheduledTest.unitName.map { [$0] } ?? [],
                difficulty: difficultyFromInt(scheduledTest.difficulty),
                questionCount: (scheduledTest.estimatedMinutes ?? 30) / 3
            )
            
            await practiceStore.generateTest(request: request)
        }
        
        selectedTest = nil
    }
    
    private func difficultyFromInt(_ level: Int) -> PracticeTestDifficulty {
        switch level {
        case 1...2: return .easy
        case 4...5: return .hard
        default: return .medium
        }
    }
}

/// Individual scheduled test row for iOS
struct IOSScheduledTestRow: View {
    let test: ScheduledPracticeTest
    let hasCompletedAttempt: Bool
    let onStart: () -> Void
    
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
                        Label("\(duration) min", systemImage: "timer")
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
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(16)
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
            return .blue.opacity(0.2)
        case .completed:
            return .green.opacity(0.2)
        case .missed:
            return .orange.opacity(0.2)
        case .archived:
            return Color.secondary.opacity(0.1)
        }
    }
}

#endif
