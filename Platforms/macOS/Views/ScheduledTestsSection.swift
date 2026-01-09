#if os(macOS)
    import SwiftUI

    /// Section displaying scheduled practice tests with status badges
    struct ScheduledTestsSection: View {
        @ObservedObject var store: ScheduledTestsStore
        let onStartTest: (ScheduledPracticeTest) -> Void

        private var upcomingTests: [ScheduledPracticeTest] {
            store.scheduledTests
                .filter { $0.status != .archived }
                .sorted { $0.scheduledAt < $1.scheduledAt }
        }

        var body: some View {
            if !upcomingTests.isEmpty {
                VStack(spacing: 12) {
                    ForEach(upcomingTests) { test in
                        ScheduledTestRow(
                            test: test,
                            hasCompletedAttempt: store.hasCompletedAttempt(for: test.id),
                            onStart: { onStartTest(test) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    /// Individual row for a scheduled test
    private struct ScheduledTestRow: View {
        let test: ScheduledPracticeTest
        let hasCompletedAttempt: Bool
        let onStart: () -> Void

        @State private var isHovered = false

        private var currentStatus: ScheduledTestStatus {
            test.currentStatus(hasCompletedAttempt: hasCompletedAttempt)
        }

        private var canStart: Bool {
            currentStatus == .scheduled || currentStatus == .missed
        }

        var body: some View {
            HStack(spacing: 16) {
                // Left side: Test info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(test.title)
                            .font(.body.weight(.semibold))
                            .lineLimit(1)

                        TestStatusBadge(status: currentStatus, isCompact: false)
                    }

                    HStack(spacing: 12) {
                        Label(test.subject, systemImage: "book")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let unit = test.unitName {
                            Label(unit, systemImage: "folder")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let duration = test.estimatedMinutes {
                            Label(
                                NSLocalizedString(
                                    "ui.label.duration.min",
                                    value: "\(duration) min",
                                    comment: "\(duration) min"
                                ),
                                systemImage: "clock"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Right side: Schedule time and action
                VStack(alignment: .trailing, spacing: 6) {
                    Text(test.scheduledAt, style: .date)
                        .font(.caption.weight(.medium))

                    Text(test.scheduledAt, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if canStart {
                        Button(action: onStart) {
                            Text(currentStatus == .missed ? "Start Anyway" : "Start")
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isHovered ? Color.primary.opacity(0.03) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            .contextMenu {
                if canStart {
                    Button(NSLocalizedString("ui.button.start.test", value: "Start Test", comment: "Start Test")) {
                        onStart()
                    }
                }

                Button(NSLocalizedString("ui.button.view.details", value: "View Details", comment: "View Details")) {
                    // Could open a detail sheet if implemented
                }

                Divider()

                Button(NSLocalizedString("ui.button.edit.schedule", value: "Edit Schedule", comment: "Edit Schedule")) {
                    // Could open an edit sheet if implemented
                }

                Button(NSLocalizedString("Delete Test", value: "Delete Test", comment: ""), role: .destructive) {
                    // Could trigger deletion
                }
            }
        }
    }

#endif
