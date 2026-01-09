#if os(macOS)
    import SwiftUI

    struct DeveloperSettingsView: View {
        @ObservedObject private var diagnostics = Diagnostics.shared
        @ObservedObject private var settings = AppSettingsModel.shared

        var body: some View {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(
                            NSLocalizedString(
                                "settings.toggle.developer.mode",
                                value: "Developer Mode",
                                comment: "Developer Mode"
                            ),
                            isOn: $settings.devModeEnabled
                        )
                        .font(.headline)
                        .onChange(of: settings.devModeEnabled) { _, _ in
                            settings.save()
                        }

                        Text(NSLocalizedString(
                            "settings.when.enabled.the.app.emits",
                            value: "When enabled, the app emits structured debug logging to the Xcode console. This helps with debugging, triage, and understanding app behavior at runtime.",
                            comment: "When enabled, the app emits structured debug loggi..."
                        ))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                } header: {
                    Text(NSLocalizedString("settings.debug.logging", value: "Debug Logging", comment: "Debug Logging"))
                }

                if diagnostics.isDeveloperModeEnabled {
                    Section {
                        NavigationLink(destination: MainThreadDebuggerView()) {
                            HStack {
                                Image(systemName: "ant.circle.fill")
                                    .foregroundColor(.red)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(NSLocalizedString(
                                        "settings.main.thread.debugger",
                                        value: "Main Thread Debugger",
                                        comment: "Main Thread Debugger"
                                    ))
                                    .font(.headline)
                                    Text(NSLocalizedString(
                                        "settings.track.ui.freezes.and.performance.issues",
                                        value: "Track UI freezes and performance issues",
                                        comment: "Track UI freezes and performance issues"
                                    ))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text(NSLocalizedString(
                            "settings.performance.debugging",
                            value: "Performance Debugging",
                            comment: "Performance Debugging"
                        ))
                    } footer: {
                        Text(NSLocalizedString(
                            "settings.advanced.tool.to.detect.main",
                            value: "Advanced tool to detect main thread blocks, long operations, and memory issues.",
                            comment: "Advanced tool to detect main thread blocks, long o..."
                        ))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    #if DEBUG || DEVELOPER_MODE
                        Section {
                            NavigationLink(destination: AutoRescheduleCounterView()) {
                                HStack {
                                    Image(systemName: "shield.lefthalf.filled")
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(NSLocalizedString(
                                            "settings.autoreschedule.counters",
                                            value: "Auto-Reschedule Counters",
                                            comment: "Auto-Reschedule Counters"
                                        ))
                                        .font(.headline)
                                        Text(NSLocalizedString(
                                            "settings.verify.invariant.enforcement.and.suppressions",
                                            value: "Verify invariant enforcement and suppressions",
                                            comment: "Verify invariant enforcement and suppressions"
                                        ))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                        } header: {
                            Text(NSLocalizedString(
                                "settings.autoreschedule.debugging",
                                value: "Auto-Reschedule Debugging",
                                comment: "Auto-Reschedule Debugging"
                            ))
                        }
                    #endif

                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(
                                NSLocalizedString(
                                    "settings.toggle.ui.logging",
                                    value: "UI Logging",
                                    comment: "UI Logging"
                                ),
                                isOn: $settings.devModeUILogging
                            )
                            .onChange(of: settings.devModeUILogging) { _, _ in settings.save() }
                            Toggle(
                                NSLocalizedString(
                                    "settings.toggle.data.sync.logging",
                                    value: "Data & Sync Logging",
                                    comment: "Data & Sync Logging"
                                ),
                                isOn: $settings.devModeDataLogging
                            )
                            .onChange(of: settings.devModeDataLogging) { _, _ in settings.save() }
                            Toggle(
                                NSLocalizedString(
                                    "settings.toggle.scheduler.planner.logging",
                                    value: "Scheduler & Planner Logging",
                                    comment: "Scheduler & Planner Logging"
                                ),
                                isOn: $settings.devModeSchedulerLogging
                            )
                            .onChange(of: settings.devModeSchedulerLogging) { _, _ in settings.save() }
                            Toggle(
                                NSLocalizedString(
                                    "settings.toggle.performance.warnings",
                                    value: "Performance Warnings",
                                    comment: "Performance Warnings"
                                ),
                                isOn: $settings.devModePerformance
                            )
                            .onChange(of: settings.devModePerformance) { _, _ in settings.save() }
                        }
                    } header: {
                        Text(NSLocalizedString(
                            "settings.subsystem.toggles",
                            value: "Subsystem Toggles",
                            comment: "Subsystem Toggles"
                        ))
                    } footer: {
                        Text(NSLocalizedString(
                            "settings.finetune.which.subsystems.emit.debug",
                            value: "Fine-tune which subsystems emit debug logs. Errors and warnings are always logged.",
                            comment: "Fine-tune which subsystems emit debug logs. Errors..."
                        ))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString(
                                "settings.active.subsystems",
                                value: "Active Subsystems",
                                comment: "Active Subsystems"
                            ))
                            .font(.headline)

                            ScrollView {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(LogSubsystem.allCases, id: \.self) { subsystem in
                                        HStack {
                                            Image(systemName: "circle.fill")
                                                .font(.system(size: 6))
                                                .foregroundColor(.green)
                                            Text(subsystem.rawValue)
                                                .font(.caption)
                                                .monospaced()
                                        }
                                    }
                                }
                                .padding(8)
                            }
                            .frame(maxHeight: 200)
                            .background(.secondaryBackground)
                            .cornerRadius(6)
                        }
                    } header: {
                        Text(NSLocalizedString(
                            "settings.available.subsystems",
                            value: "Available Subsystems",
                            comment: "Available Subsystems"
                        ))
                    } footer: {
                        Text(NSLocalizedString(
                            "settings.all.subsystems.are.actively.logging",
                            value: "All subsystems are actively logging when Developer Mode is enabled.",
                            comment: "All subsystems are actively logging when Developer..."
                        ))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(verbatim: "Recent Events: \(diagnostics.recentEvents.count)")
                                .font(.headline)

                            Button(NSLocalizedString(
                                "settings.button.clear.event.buffer",
                                value: "Clear Event Buffer",
                                comment: "Clear Event Buffer"
                            )) {
                                diagnostics.clearBuffer()
                            }

                            if !diagnostics.recentEvents.isEmpty {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 2) {
                                        ForEach(
                                            diagnostics.recentEvents.suffix(50).reversed(),
                                            id: \.timestamp
                                        ) { event in
                                            HStack(alignment: .top, spacing: 4) {
                                                Text(event.severity.rawValue)
                                                    .font(.caption2)
                                                    .monospaced()
                                                    .foregroundColor(colorForSeverity(event.severity))
                                                    .frame(width: 50, alignment: .leading)

                                                Text(verbatim: "[\(event.subsystem.rawValue)]")
                                                    .font(.caption2)
                                                    .monospaced()
                                                    .foregroundColor(.secondary)
                                                    .frame(width: 100, alignment: .leading)

                                                Text(event.message)
                                                    .font(.caption2)
                                                    .lineLimit(2)
                                            }
                                        }
                                    }
                                    .padding(8)
                                }
                                .frame(maxHeight: 300)
                                .background(.secondaryBackground)
                                .cornerRadius(6)
                            }
                        }
                    } header: {
                        Text(NSLocalizedString(
                            "settings.event.buffer.last.50",
                            value: "Event Buffer (Last 50)",
                            comment: "Event Buffer (Last 50)"
                        ))
                    } footer: {
                        Text(NSLocalizedString(
                            "settings.view.recent.log.events.full",
                            value: "View recent log events. Full logs are available in Console.app filtered by subsystem 'com.itori.app'.",
                            comment: "View recent log events. Full logs are available in..."
                        ))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString(
                            "settings.privacy.safety",
                            value: "Privacy & Safety",
                            comment: "Privacy & Safety"
                        ))
                        .font(.headline)

                        VStack(alignment: .leading, spacing: 4) {
                            bulletPoint("Logs do not contain sensitive user content")
                            bulletPoint("Only IDs, counts, and high-level summaries are logged")
                            bulletPoint("All logs are local only—no external upload")
                            bulletPoint("Use Console.app to view full structured logs")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Developer")
        }

        private func colorForSeverity(_ severity: LogSeverity) -> Color {
            switch severity {
            case .fatal: .red
            case .error: .orange
            case .warn: .yellow
            case .info: .blue
            case .debug: .secondary
            }
        }

        private func bulletPoint(_ text: String) -> some View {
            HStack(alignment: .top, spacing: 4) {
                Text(NSLocalizedString("settings.", value: "•", comment: "•"))
                Text(text)
            }
        }
    }

    struct DeveloperSettingsView_Old: View {
        // This file intentionally kept as compatibility; UI is located in SettingsRootView's DeveloperSettingsView
        var body: some View { EmptyView() }
    }
#endif
