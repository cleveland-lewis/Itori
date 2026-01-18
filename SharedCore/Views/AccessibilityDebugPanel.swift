//
//  AccessibilityDebugPanel.swift
//  Itori
//
//  Created on 2026-01-03.
//

import SwiftUI

#if DEBUG

    // MARK: - Accessibility Debug Panel

    /// Debug panel for testing accessibility features
    struct AccessibilityDebugPanel: View {
        @StateObject private var auditEngine = AccessibilityAuditEngine.shared
        @State private var selectedTab = 0
        @State private var filterSeverity: AccessibilityAuditResult.Severity?
        @State private var filterCategory: AccessibilityAuditResult.Category?
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {
                VStack(spacing: 0) {
                    // Header Stats
                    statsHeader

                    Divider()

                    // Tab Selection
                    Picker("View", selection: $selectedTab) {
                        Text(verbatim: "Issues (\(auditEngine.totalIssues))").tag(0)
                        Text(NSLocalizedString("ui.live.testing", value: "Live Testing", comment: "Live Testing"))
                            .tag(1)
                        Text(NSLocalizedString("ui.settings", value: "Settings", comment: "Settings")).tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    // Content
                    TabView(selection: $selectedTab) {
                        issuesView.tag(0)
                        liveTestingView.tag(1)
                        settingsView.tag(2)
                    }
                }
                .navigationTitle(NSLocalizedString(
                    "ui.accessibility.debug",
                    value: "Accessibility Debug",
                    comment: "Accessibility Debug navigation title"
                ))
                #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(NSLocalizedString("ui.button.close", value: "Close", comment: "Close")) { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { Task { await auditEngine.runFullAudit() } }) {
                            Label(
                                NSLocalizedString("ui.label.scan", value: "Scan", comment: "Scan"),
                                systemImage: "arrow.clockwise"
                            )
                        }
                        .disabled(auditEngine.isScanning)
                    }
                }
            }
            .task {
                if auditEngine.results.isEmpty {
                    await auditEngine.runFullAudit()
                }
            }
        }

        // MARK: - Stats Header

        private var statsHeader: some View {
            HStack(spacing: 16) {
                StatBadge(
                    count: auditEngine.criticalCount,
                    severity: .critical,
                    label: "Critical"
                )

                StatBadge(
                    count: auditEngine.highCount,
                    severity: .high,
                    label: "High"
                )

                StatBadge(
                    count: auditEngine.mediumCount,
                    severity: .medium,
                    label: "Medium"
                )

                StatBadge(
                    count: auditEngine.lowCount,
                    severity: .low,
                    label: "Low"
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
        }

        // MARK: - Issues View

        private var issuesView: some View {
            VStack(spacing: 0) {
                // Filters
                filterBar

                if auditEngine.isScanning {
                    scanningView
                } else if filteredResults.isEmpty {
                    emptyStateView
                } else {
                    issuesList
                }
            }
        }

        private var filterBar: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    severityFilters

                    Divider()
                        .frame(height: 24)

                    categoryFilters
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            #if os(macOS)
                .background(Color.gray.opacity(0.1))
            #else
                .background(Color(uiColor: .systemBackground))
            #endif
        }

        private var severityFilters: some View {
            ForEach(AccessibilityAuditResult.Severity.allCases, id: \.self) { severity in
                FilterChip(
                    title: severity.rawValue,
                    isSelected: filterSeverity == severity,
                    color: severity.color
                ) {
                    filterSeverity = filterSeverity == severity ? nil : severity
                }
            }
        }

        private var categoryFilters: some View {
            ForEach(AccessibilityAuditResult.Category.allCases.prefix(5), id: \.self) { category in
                FilterChip(
                    title: category.rawValue,
                    isSelected: filterCategory == category,
                    color: .blue
                ) {
                    filterCategory = filterCategory == category ? nil : category
                }
            }
        }

        private var issuesList: some View {
            List(filteredResults) { result in
                NavigationLink(destination: IssueDetailView(result: result)) {
                    IssueRow(result: result)
                }
            }
            .listStyle(.plain)
        }

        private var scanningView: some View {
            VStack(spacing: 16) {
                ProgressView(value: auditEngine.scanProgress) {
                    Text(NSLocalizedString(
                        "ui.scanning.accessibility",
                        value: "Scanning accessibility...",
                        comment: "Progress text shown while scanning accessibility"
                    ))
                    .font(.headline)
                }
                .progressViewStyle(.linear)

                Text(verbatim: "\(Int(auditEngine.scanProgress * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        private var emptyStateView: some View {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text(NSLocalizedString("ui.no.issues.found", value: "No Issues Found", comment: "No Issues Found"))
                    .font(.headline)

                Text(NSLocalizedString(
                    "ui.your.app.meets.accessibility.standards",
                    value: "Your app meets accessibility standards!",
                    comment: "Message shown when no accessibility issues are found"
                ))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        private var filteredResults: [AccessibilityAuditResult] {
            auditEngine.results.filter { result in
                if let severity = filterSeverity, result.severity != severity {
                    return false
                }
                if let category = filterCategory, result.category != category {
                    return false
                }
                return true
            }
        }

        // MARK: - Live Testing View

        private var liveTestingView: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Current Accessibility Settings")

                    #if os(iOS)
                        SettingRow(
                            icon: "eye.slash",
                            title: "VoiceOver",
                            value: UIAccessibility.isVoiceOverRunning ? "Enabled" : "Disabled",
                            color: .blue
                        )

                        SettingRow(
                            icon: "textformat.size",
                            title: "Dynamic Type",
                            value: "\(UIFont.preferredFont(forTextStyle: .body).pointSize) pt",
                            color: .green
                        )

                        SettingRow(
                            icon: "moon.fill",
                            title: "Reduce Motion",
                            value: UIAccessibility.isReduceMotionEnabled ? "Enabled" : "Disabled",
                            color: .purple
                        )

                        SettingRow(
                            icon: "decrease.indent",
                            title: "Reduce Transparency",
                            value: UIAccessibility.isReduceTransparencyEnabled ? "Enabled" : "Disabled",
                            color: .orange
                        )

                        SettingRow(
                            icon: "sun.max.fill",
                            title: "Increase Contrast",
                            value: UIAccessibility.isDarkerSystemColorsEnabled ? "Enabled" : "Disabled",
                            color: .yellow
                        )
                    #else
                        SettingRow(
                            icon: "eye.slash",
                            title: "VoiceOver",
                            value: NSWorkspace.shared.isVoiceOverEnabled ? "Enabled" : "Disabled",
                            color: .blue
                        )

                        SettingRow(
                            icon: "textformat.size",
                            title: "Dynamic Type",
                            value: "System",
                            color: .green
                        )

                        SettingRow(
                            icon: "moon.fill",
                            title: "Reduce Motion",
                            value: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? "Enabled" : "Disabled",
                            color: .purple
                        )

                        SettingRow(
                            icon: "decrease.indent",
                            title: "Reduce Transparency",
                            value: NSWorkspace.shared
                                .accessibilityDisplayShouldReduceTransparency ? "Enabled" : "Disabled",
                            color: .orange
                        )

                        SettingRow(
                            icon: "sun.max.fill",
                            title: "Increase Contrast",
                            value: NSWorkspace.shared
                                .accessibilityDisplayShouldIncreaseContrast ? "Enabled" : "Disabled",
                            color: .yellow
                        )
                    #endif

                    Divider()

                    SectionHeader(title: "Quick Actions")

                    QuickActionButton(
                        icon: "speaker.wave.2",
                        title: "Announce Test",
                        color: .blue
                    ) {
                        announceTest()
                    }

                    QuickActionButton(
                        icon: "eye",
                        title: "Simulate VoiceOver",
                        color: .green
                    ) {
                        // Opens Settings for user to enable
                    }

                    QuickActionButton(
                        icon: "square.grid.2x2",
                        title: "View Element Tree",
                        color: .purple
                    ) {
                        // Show element hierarchy
                    }

                    Divider()

                    SectionHeader(title: "Testing Checklist")

                    ChecklistItem(text: "Test with VoiceOver enabled", isComplete: false)
                    ChecklistItem(text: "Test at largest text size", isComplete: false)
                    ChecklistItem(text: "Test with Reduce Motion enabled", isComplete: false)
                    ChecklistItem(text: "Test keyboard navigation (macOS)", isComplete: false)
                    ChecklistItem(text: "Test with high contrast mode", isComplete: false)
                    ChecklistItem(text: "Test color blind simulation", isComplete: false)
                }
                .padding()
            }
        }

        // MARK: - Settings View

        private var settingsView: some View {
            Form {
                Section("Audit Configuration") {
                    Toggle(
                        NSLocalizedString(
                            "ui.toggle.autorun.on.app.launch",
                            value: "Auto-run on app launch",
                            comment: "Auto-run on app launch"
                        ),
                        isOn: .constant(false)
                    )
                    Toggle(
                        NSLocalizedString(
                            "ui.toggle.show.severity.badges.in.ui",
                            value: "Show severity badges in UI",
                            comment: "Show severity badges in UI"
                        ),
                        isOn: .constant(true)
                    )
                    Toggle(
                        NSLocalizedString(
                            "ui.toggle.enable.accessibility.logging",
                            value: "Enable accessibility logging",
                            comment: "Enable accessibility logging"
                        ),
                        isOn: .constant(false)
                    )
                }

                Section("WCAG Compliance Level") {
                    Picker("Target Level", selection: .constant("AA")) {
                        Text(NSLocalizedString("ui.a.minimum", value: "A - Minimum", comment: "A - Minimum")).tag("A")
                        Text(NSLocalizedString("ui.aa.standard", value: "AA - Standard", comment: "AA - Standard"))
                            .tag("AA")
                        Text(NSLocalizedString("ui.aaa.enhanced", value: "AAA - Enhanced", comment: "AAA - Enhanced"))
                            .tag("AAA")
                    }
                }

                Section("Ignored Issues") {
                    Text(NSLocalizedString(
                        "ui.no.ignored.issues",
                        value: "No ignored issues",
                        comment: "No ignored issues"
                    ))
                    .foregroundColor(.secondary)
                }

                Section {
                    Button(NSLocalizedString(
                        "ui.button.export.audit.report",
                        value: "Export Audit Report",
                        comment: "Export Audit Report"
                    )) {
                        exportReport()
                    }

                    Button(NSLocalizedString(
                        "ui.button.clear.audit.cache",
                        value: "Clear Audit Cache",
                        comment: "Clear Audit Cache"
                    )) {
                        // Clear cache
                    }
                    .foregroundColor(.red)
                }

                Section("About") {
                    HStack {
                        Text(NSLocalizedString("ui.last.scan", value: "Last Scan", comment: "Last Scan"))
                        Spacer()
                        if let date = auditEngine.lastScanDate {
                            Text(date.formatted())
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text(NSLocalizedString("ui.total.issues", value: "Total Issues", comment: "Total Issues"))
                        Spacer()
                        Text(verbatim: "\(auditEngine.totalIssues)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }

        // MARK: - Helper Functions

        private func announceTest() {
            #if os(iOS)
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "This is a test announcement for VoiceOver users."
                )
            #endif
        }

        private func exportReport() {
            // Deferred: export audit results
            print("Exporting audit report...")
        }
    }

    // MARK: - Supporting Views

    private struct StatBadge: View {
        let count: Int
        let severity: AccessibilityAuditResult.Severity
        let label: String

        var body: some View {
            VStack(spacing: 4) {
                Text(verbatim: "\(count)")
                    .font(.title2.bold())
                    .foregroundColor(severity.color)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private struct FilterChip: View {
        let title: String
        let isSelected: Bool
        let color: Color
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                #if os(iOS)
                    .background(isSelected ? color.opacity(0.2) : Color(.secondarySystemBackground))
                #else
                    .background(isSelected ? color.opacity(0.2) : Color(NSColor.controlBackgroundColor))
                #endif
                    .foregroundColor(isSelected ? color : .primary)
                    .cornerRadius(16)
            }
        }
    }

    private struct IssueRow: View {
        let result: AccessibilityAuditResult

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: result.severity.icon)
                    .foregroundColor(result.severity.color)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.issue)
                        .font(.subheadline.bold())

                    Text(result.location)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        Text(result.category.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)

                        if let wcag = result.wcagCriteria {
                            Text(wcag)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    private struct IssueDetailView: View {
        let result: AccessibilityAuditResult
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Issue Header
                    HStack(alignment: .top) {
                        Image(systemName: result.severity.icon)
                            .font(.largeTitle)
                            .foregroundColor(result.severity.color)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.severity.rawValue)
                                .font(.caption.bold())
                                .foregroundColor(result.severity.color)

                            Text(result.issue)
                                .font(.title2.bold())
                        }
                    }

                    Divider()

                    // Location
                    DetailSection(title: "Location", icon: "location") {
                        Text(result.location)
                    }

                    // Recommendation
                    DetailSection(title: "How to Fix", icon: "wrench.and.screwdriver") {
                        Text(result.recommendation)
                    }

                    // WCAG Criteria
                    if let wcag = result.wcagCriteria {
                        DetailSection(title: "WCAG Criteria", icon: "checkmark.seal") {
                            Text(wcag)
                        }
                    }

                    // Category
                    DetailSection(title: "Category", icon: "folder") {
                        Text(result.category.rawValue)
                    }

                    Spacer()

                    // Actions
                    VStack(spacing: 12) {
                        Button(action: { /* Copy details */ }) {
                            Label(
                                NSLocalizedString(
                                    "ui.label.copy.details",
                                    value: "Copy Details",
                                    comment: "Copy Details"
                                ),
                                systemImage: "doc.on.doc"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.itoriLiquidProminent)

                        Button(action: { /* Mark as fixed */ }) {
                            Label(
                                NSLocalizedString(
                                    "ui.label.mark.as.fixed",
                                    value: "Mark as Fixed",
                                    comment: "Mark as Fixed"
                                ),
                                systemImage: "checkmark.circle"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.itoriLiquidProminent)

                        Button(action: { /* Ignore issue */ }) {
                            Text(NSLocalizedString(
                                "ui.ignore.this.issue",
                                value: "Ignore This Issue",
                                comment: "Ignore This Issue"
                            ))
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.itoriLiquidProminent)
                        .tint(.red)
                    }
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString(
                "ui.issue.details",
                value: "Issue Details",
                comment: "Issue details navigation title"
            ))
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private struct DetailSection<Content: View>: View {
        let title: String
        let icon: String
        @ViewBuilder let content: () -> Content

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon)
                    .font(.headline)

                content()
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }

    private struct SectionHeader: View {
        let title: String

        var body: some View {
            Text(title)
                .font(.headline)
                .padding(.top, 8)
        }
    }

    private struct SettingRow: View {
        let icon: String
        let title: String
        let value: String
        let color: Color

        var body: some View {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 30)

                Text(title)

                Spacer()

                Text(value)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }

    private struct QuickActionButton: View {
        let icon: String
        let title: String
        let color: Color
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .frame(width: 30)

                    Text(title)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    private struct ChecklistItem: View {
        let text: String
        let isComplete: Bool

        var body: some View {
            HStack {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isComplete ? .green : .secondary)

                Text(text)
                    .foregroundColor(isComplete ? .secondary : .primary)

                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - UIColor Extension

    #if os(iOS)
        private extension Color {
            init(uiColor: UIColor) {
                self.init(uiColor)
            }
        }
    #endif

#endif
