//
// AutoRescheduleCounterView.swift
// Dev-Only Auto-Reschedule Counter Panel
//

import SwiftUI

#if DEBUG || DEVELOPER_MODE

    struct AutoRescheduleCounterView: View {
        @Environment(\.dismiss) private var dismiss
        @State private var counters = AutoRescheduleCounters()

        var body: some View {
            VStack(spacing: 0) {
                // Custom toolbar with back button
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Settings")
                                .font(.subheadline)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                    .help("Back to Developer Settings")

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(nsColor: .windowBackgroundColor))

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString(
                                "autoreschedulecounter.navigation.title",
                                value: "Auto-Reschedule Counters",
                                comment: "Auto-Reschedule counters navigation title"
                            ))
                            .font(.title2.bold())

                            Text(NSLocalizedString(
                                "autoreschedulecounter.these.counters.must.remain.zero",
                                value: "These counters must remain zero when Auto-Reschedule is OFF. Only 'Suppressed' should increment.",
                                comment: "Description of counter invariants when auto-reschedule is disabled"
                            ))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Activity Section
                        GroupBox("Activity") {
                            VStack(spacing: 12) {
                                counterRow(title: "Checks Executed", value: counters.checksExecuted)
                                Divider()
                                counterRow(title: "Sessions Analyzed", value: counters.sessionsAnalyzed)
                                Divider()
                                counterRow(title: "Sessions Moved", value: counters.sessionsMoved)
                                Divider()
                                counterRow(title: "History Entries Written", value: counters.historyEntriesWritten)
                                Divider()
                                counterRow(title: "Notifications Scheduled", value: counters.notificationsScheduled)
                                Divider()
                                counterRow(
                                    title: "Suppressed Executions",
                                    value: counters.suppressedExecutions,
                                    critical: false
                                )
                            }
                            .padding(12)
                        }
                        .padding(.horizontal, 20)

                        // Invariant Status Section
                        GroupBox("Invariant Status") {
                            VStack(alignment: .leading, spacing: 12) {
                                let enabled = AppSettingsModel.shared.enableAutoReschedule
                                HStack {
                                    Text(NSLocalizedString(
                                        "autoreschedulecounter.autoreschedule.enabled",
                                        value: "Auto-Reschedule Enabled:",
                                        comment: "Auto-Reschedule Enabled:"
                                    ))
                                    Spacer()
                                    Text(enabled ? "YES" : "NO")
                                        .foregroundColor(enabled ? .green : .red)
                                        .fontWeight(.bold)
                                }

                                if !enabled {
                                    let hasViolation = counters.checksExecuted > 0 || counters
                                        .sessionsAnalyzed > 0 || counters
                                        .sessionsMoved > 0 || counters.historyEntriesWritten > 0 || counters
                                        .notificationsScheduled > 0

                                    Divider()

                                    Label(
                                        hasViolation ? "❌ Enforcement: FAILING" : "✅ Enforcement: PASSING",
                                        systemImage: hasViolation ? "xmark.shield.fill" : "checkmark.shield.fill"
                                    )
                                    .foregroundColor(hasViolation ? .red : .green)
                                }

                                if let lastReason = counters.lastSuppressionReason {
                                    Divider()

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(NSLocalizedString(
                                            "autoreschedulecounter.last.suppression",
                                            value: "Last Suppression:",
                                            comment: "Last Suppression:"
                                        ))
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                        Text(lastReason)
                                            .font(.caption.monospaced())
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(12)
                        }
                        .padding(.horizontal, 20)

                        // Actions Section
                        GroupBox("Actions") {
                            VStack(spacing: 12) {
                                Button(NSLocalizedString(
                                    "autoreschedulecounter.button.refresh.counters",
                                    value: "Refresh Counters",
                                    comment: "Refresh Counters"
                                )) {
                                    refreshCounters()
                                }
                                .buttonStyle(.itoriLiquidProminent)
                                .frame(maxWidth: .infinity)

                                Button(NSLocalizedString(
                                    "autoreschedulecounter.button.reset.counters",
                                    value: "Reset Counters",
                                    comment: "Reset Counters"
                                )) {
                                    AutoRescheduleActivityCounter.shared.reset()
                                    refreshCounters()
                                }
                                .buttonStyle(.itoriLiquidProminent)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                            }
                            .padding(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .frame(minWidth: 560, minHeight: 480)
            .onAppear {
                refreshCounters()
            }
        }

        private func refreshCounters() {
            counters = AutoRescheduleActivityCounter.shared.snapshot()
        }

        @ViewBuilder
        private func counterRow(title: String, value: Int, critical: Bool = true) -> some View {
            HStack {
                Text(title)
                Spacer()
                Text(verbatim: "\(value)")
                    .fontWeight(.bold)
                    .foregroundColor(critical && value > 0 && !AppSettingsModel.shared
                        .enableAutoReschedule ? .red : .primary)
            }
        }
    }

#endif
