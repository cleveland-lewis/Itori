//
// AutoRescheduleCounterView.swift
// Dev-Only Auto-Reschedule Counter Panel
//

import SwiftUI

#if DEBUG || DEVELOPER_MODE

struct AutoRescheduleCounterView: View {
    @State private var counters = AutoRescheduleCounters()

    var body: some View {
        Form {
            Section {
                Text("Auto-Reschedule Invariant Counters")
                    .font(.headline)
                Text("These counters must remain zero when Auto-Reschedule is OFF. Only 'Suppressed' should increment.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Activity") {
                counterRow(title: "Checks Executed", value: counters.checksExecuted)
                counterRow(title: "Sessions Analyzed", value: counters.sessionsAnalyzed)
                counterRow(title: "Sessions Moved", value: counters.sessionsMoved)
                counterRow(title: "History Entries Written", value: counters.historyEntriesWritten)
                counterRow(title: "Notifications Scheduled", value: counters.notificationsScheduled)
                counterRow(title: "Suppressed Executions", value: counters.suppressedExecutions, critical: false)
            }

            Section("Invariant Status") {
                let enabled = AppSettingsModel.shared.enableAutoReschedule
                HStack {
                    Text("Auto-Reschedule Enabled:")
                    Spacer()
                    Text(enabled ? "YES" : "NO")
                        .foregroundColor(enabled ? .green : .red)
                        .fontWeight(.bold)
                }

                if !enabled {
                    let hasViolation = counters.checksExecuted > 0 || counters.sessionsAnalyzed > 0 || counters.sessionsMoved > 0 || counters.historyEntriesWritten > 0 || counters.notificationsScheduled > 0
                    Label(hasViolation ? "❌ Enforcement: FAILING" : "✅ Enforcement: PASSING", systemImage: hasViolation ? "xmark.shield.fill" : "checkmark.shield.fill")
                        .foregroundColor(hasViolation ? .red : .green)
                }

                if let lastReason = counters.lastSuppressionReason {
                    HStack {
                        Text("Last Suppression:")
                        Spacer()
                        Text(lastReason)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("Actions") {
                Button("Refresh Counters") { refreshCounters() }
                Button("Reset Counters") {
                    AutoRescheduleActivityCounter.shared.reset()
                    refreshCounters()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Auto-Reschedule Counters")
        #if os(macOS)
        .frame(minWidth: 560, minHeight: 480)
        #endif
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
            Text("\(value)")
                .fontWeight(.bold)
                .foregroundColor(critical && value > 0 && !AppSettingsModel.shared.enableAutoReschedule ? .red : .primary)
        }
    }
}

#endif
