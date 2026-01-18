import SwiftUI
#if os(iOS)

    import UIKit

    struct IOSStorageSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel
        @EnvironmentObject var timerManager: TimerManager
        @State private var storageSize: String = NSLocalizedString(
            "settings.storage.calculating",
            value: "Calculating...",
            comment: "Storage size calculating"
        )
        @State private var storageLocation: String = ""
        @State private var showingClearCacheConfirmation = false
        @State private var showingExportSheet = false
        @State private var shareItem: ShareItem?
        @State private var isExporting = false
        @State private var exportIncludeTasks = true
        @State private var exportIncludeCourses = true
        @State private var exportIncludeSemesters = true
        @State private var exportIncludePlannerSessions = true
        @State private var exportIncludeSettings = true
        @State private var exportError: String?
        @State private var statusLabel: String = NSLocalizedString(
            "settings.storage.status.disconnected",
            value: "Disconnected",
            comment: "Storage status disconnected"
        )
        @State private var syncTimeoutWorkItem: DispatchWorkItem?

        // Reset data state
        @State private var showResetAlert = false
        @State private var resetCode: String = ""
        @State private var resetInput: String = ""
        @State private var isResetting = false

        var body: some View {
            List {
                Section {
                    HStack {
                        Text(NSLocalizedString("settings.storage.used", value: "Data Used", comment: "Storage Used"))
                        Spacer()
                        Text(storageSize)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text(NSLocalizedString("settings.storage.location", comment: "Location"))
                        Spacer()
                        Text(storageLocation.isEmpty
                            ? NSLocalizedString("settings.storage.location.local", comment: "Local")
                            : storageLocation)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(1)
                    }
                } header: {
                    Text(NSLocalizedString("settings.storage.info.header", value: "Data", comment: "Storage"))
                }

                Section {
                    Toggle(isOn: $settings.enableICloudSync) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("settings.privacy.icloud_sync", comment: "iCloud Sync"))
                            Text(NSLocalizedString(
                                "settings.privacy.icloud_sync.detail",
                                comment: "Sync data across your devices using iCloud"
                            ))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: settings.enableICloudSync) { _, newValue in
                        settings.save()
                        statusLabel = NSLocalizedString(
                            "settings.storage.status.syncing",
                            value: "Syncing",
                            comment: "Storage status syncing"
                        )
                        scheduleSyncTimeout()
                        NotificationCenter.default.post(
                            name: .iCloudSyncSettingChanged,
                            object: newValue
                        )
                    }
                    Text(String(
                        format: NSLocalizedString(
                            "settings.storage.status.label",
                            value: "Status: %@",
                            comment: "Storage status label"
                        ),
                        statusLabel
                    ))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                } header: {
                    Text(NSLocalizedString("settings.privacy.data.header", value: "Data", comment: "Data Storage"))
                } footer: {
                    if PersistenceController.shared.isCloudKitEnabled {
                        Text(NSLocalizedString(
                            "settings.storage.icloud.connected",
                            value: "iCloud is connected and protected by native iCloud protections",
                            comment: "iCloud connected footer"
                        ))
                    } else {
                        Text(NSLocalizedString(
                            "settings.privacy.local_only.footer",
                            comment: "All your data stays on this device. No cloud sync or external services are used."
                        ))
                    }
                }

                Section {
                    Button {
                        showingClearCacheConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text(NSLocalizedString(
                                "settings.storage.clear_cache",
                                value: "Clear Cache",
                                comment: "Clear Cache"
                            ))
                        }
                    }
                    .confirmationDialog(
                        NSLocalizedString("settings.storage.clear_cache.confirm.title", comment: "Clear Cache?"),
                        isPresented: $showingClearCacheConfirmation
                    ) {
                        Button(
                            NSLocalizedString("settings.storage.clear_cache.confirm.action", comment: "Clear Cache"),
                            role: .destructive
                        ) {
                            clearCache()
                        }
                        Button(NSLocalizedString("common.cancel", comment: "Cancel"), role: .cancel) {}
                    } message: {
                        Text(NSLocalizedString(
                            "settings.storage.clear_cache.confirm.message",
                            comment: "This will clear temporary files and cached data. Your tasks, courses, and settings will not be affected."
                        ))
                    }
                } header: {
                    Text(NSLocalizedString(
                        "settings.storage.maintenance.header",
                        value: "Maintenance",
                        comment: "Maintenance"
                    ))
                } footer: {
                    Text(NSLocalizedString(
                        "settings.storage.maintenance.footer",
                        value: "Clearing cache can free up data space and may improve performance",
                        comment: "Clearing cache can free up storage space and may improve performance"
                    ))
                }

                Section {
                    Button {
                        showingExportSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text(NSLocalizedString(
                                "settings.storage.export",
                                value: "Export Data",
                                comment: "Export Data"
                            ))
                        }
                    }
                } header: {
                    Text(NSLocalizedString("settings.storage.backup.header", value: "Backup", comment: "Backup"))
                } footer: {
                    Text(NSLocalizedString(
                        "settings.storage.backup.footer",
                        value: "Export your data as a backup file",
                        comment: "Export your data as a backup file"
                    ))
                }

                Section {
                    Button(role: .destructive) {
                        resetCode = ConfirmationCode.generate()
                        resetInput = ""
                        showResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .accessibilityHidden(true)
                            Text(NSLocalizedString(
                                "settings.reset.all.data",
                                value: "Reset All Data",
                                comment: "Reset All Data"
                            ))
                        }
                        .foregroundStyle(.red)
                    }
                    .accessibilityLabel(NSLocalizedString(
                        "settings.reset.all.data",
                        value: "Reset All Data",
                        comment: "Reset All Data"
                    ))
                    .accessibilityHint(NSLocalizedString(
                        "settings.reset.all.data.hint",
                        value: "Permanently deletes all app data",
                        comment: "Accessibility hint for reset button"
                    ))
                } header: {
                    Text(NSLocalizedString(
                        "settings.storage.danger_zone.header",
                        value: "Danger Zone",
                        comment: "Danger Zone"
                    ))
                } footer: {
                    Text(NSLocalizedString(
                        "settings.storage.reset.footer",
                        value: "This will permanently delete all your data including courses, assignments, and settings.",
                        comment: "Reset data warning footer"
                    ))
                }
            }
            .listStyle(.insetGrouped)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(NSLocalizedString("settings.category.storage", value: "Data", comment: "Storage"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                calculateStorageSize()
                updateStorageLocation()
                statusLabel = settings.enableICloudSync
                    ? NSLocalizedString(
                        "settings.storage.status.syncing",
                        value: "Syncing",
                        comment: "Storage status syncing"
                    )
                    : NSLocalizedString(
                        "settings.storage.status.disconnected",
                        value: "Disconnected",
                        comment: "Storage status disconnected"
                    )
            }
            .onReceive(NotificationCenter.default.publisher(for: .iCloudSyncStatusChanged)) { notification in
                let enabled = notification.object as? Bool ?? false
                let reason = notification.userInfo?["reason"] as? String
                statusLabel = statusLabelFor(enabled: enabled, reason: reason)
                syncTimeoutWorkItem?.cancel()
            }
            .alert(
                NSLocalizedString("settings.reset.all.data", value: "Reset All Data", comment: "Reset All Data"),
                isPresented: $showResetAlert
            ) {
                TextField("Enter code: \(resetCode)", text: $resetInput)
                    .autocorrectionDisabled()
                #if os(iOS)
                    .textInputAutocapitalization(.never)
                #endif
                Button(NSLocalizedString("settings.button.cancel", value: "Cancel", comment: "Cancel"), role: .cancel) {
                    showResetAlert = false
                    resetInput = ""
                }
                Button(
                    NSLocalizedString("settings.button.reset.now", value: "Reset Now", comment: "Reset Now"),
                    role: .destructive
                ) {
                    performReset()
                }
                .disabled(!resetCodeMatches || isResetting)
            } message: {
                Text(NSLocalizedString(
                    "settings.this.will.remove.all.app",
                    value: "This will remove all app data including courses, assignments, settings, and cached sessions. This action cannot be undone.",
                    comment: "Reset warning message"
                ) + "\n\n" + String(format: NSLocalizedString(
                    "settings.type.code.confirm",
                    value: "Type \"%@\" to confirm",
                    comment: "Type code to confirm"
                ), resetCode))
            }
            .sheet(isPresented: $showingExportSheet) {
                exportView
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: [item.url]) {
                    try? FileManager.default.removeItem(at: item.url)
                }
            }
            .alert(
                NSLocalizedString("settings.storage.export.error.title", comment: "Export Failed"),
                isPresented: Binding(
                    get: { exportError != nil },
                    set: { if !$0 { exportError = nil } }
                )
            ) {
                Button(NSLocalizedString("common.ok", value: "OK", comment: "OK"), role: .cancel) { exportError = nil }
            } message: {
                Text(exportError ?? NSLocalizedString(
                    "settings.storage.export.error.message",
                    comment: "Unable to create the export file right now."
                ))
            }
        }

        private func performReset() {
            guard resetCodeMatches else { return }
            isResetting = true
            AppModel.shared.requestReset()
            timerManager.stop()
            // Reset UI state
            resetInput = ""
            showResetAlert = false
            isResetting = false
        }

        private var resetCodeMatches: Bool {
            resetInput.trimmingCharacters(in: .whitespacesAndNewlines) == resetCode
        }

        private func statusLabelFor(enabled: Bool, reason: String?) -> String {
            if enabled {
                return NSLocalizedString(
                    "settings.storage.status.connected",
                    value: "Connected",
                    comment: "Storage status connected"
                )
            }
            let text = reason?.lowercased() ?? ""
            if text.contains("error") || text.contains("failed") {
                return NSLocalizedString(
                    "settings.storage.status.error",
                    value: "Error",
                    comment: "Storage status error"
                )
            }
            if text.contains("connecting") || text.contains("syncing") {
                return NSLocalizedString(
                    "settings.storage.status.syncing",
                    value: "Syncing",
                    comment: "Storage status syncing"
                )
            }
            return NSLocalizedString(
                "settings.storage.status.disconnected",
                value: "Disconnected",
                comment: "Storage status disconnected"
            )
        }

        private func scheduleSyncTimeout() {
            syncTimeoutWorkItem?.cancel()
            let workItem = DispatchWorkItem {
                if statusLabel == NSLocalizedString(
                    "settings.storage.status.syncing",
                    value: "Syncing",
                    comment: "Storage status syncing"
                ) {
                    statusLabel = NSLocalizedString(
                        "settings.storage.status.slow",
                        value: "Taking longer than usual",
                        comment: "Storage status slow"
                    )
                }
            }
            syncTimeoutWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 8 * 60, execute: workItem)
        }

        private var exportView: some View {
            NavigationStack {
                let hasSelection = exportIncludeTasks
                    || exportIncludeCourses
                    || exportIncludeSemesters
                    || exportIncludePlannerSessions
                    || exportIncludeSettings
                VStack(spacing: 20) {
                    Image(systemName: "square.and.arrow.up.circle")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .foregroundColor(.accentColor)

                    Text(NSLocalizedString("settings.storage.export.title", comment: "Export Data"))
                        .font(.title2.weight(.semibold))

                    Text(NSLocalizedString(
                        "settings.storage.export.message",
                        value: "Your data will be exported as a JSON file that you can save or share.",
                        comment: "Your data will be exported as a JSON file that you can save or share."
                    ))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(NSLocalizedString(
                            "settings.storage.export.customize",
                            value: "Customize Export",
                            comment: "Customize export section title"
                        ))
                        .font(.headline)

                        Toggle(NSLocalizedString(
                            "settings.storage.export.include.tasks",
                            value: "Tasks",
                            comment: "Export include tasks toggle"
                        ), isOn: $exportIncludeTasks)

                        Toggle(NSLocalizedString(
                            "settings.storage.export.include.courses",
                            value: "Courses",
                            comment: "Export include courses toggle"
                        ), isOn: $exportIncludeCourses)

                        Toggle(NSLocalizedString(
                            "settings.storage.export.include.semesters",
                            value: "Semesters",
                            comment: "Export include semesters toggle"
                        ), isOn: $exportIncludeSemesters)

                        Toggle(NSLocalizedString(
                            "settings.storage.export.include.sessions",
                            value: "Planner Sessions",
                            comment: "Export include planner sessions toggle"
                        ), isOn: $exportIncludePlannerSessions)

                        Toggle(NSLocalizedString(
                            "settings.storage.export.include.settings",
                            value: "Settings",
                            comment: "Export include settings toggle"
                        ), isOn: $exportIncludeSettings)
                    }
                    .padding(.horizontal)

                    Button {
                        Task {
                            await performExport()
                        }
                    } label: {
                        if isExporting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(NSLocalizedString(
                                "settings.storage.export.button",
                                value: "Export Now",
                                comment: "Export Now"
                            ))
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.itoriLiquidProminent)
                    .padding(.horizontal)
                    .disabled(isExporting || !hasSelection)
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(NSLocalizedString("common.done", comment: "Done")) {
                            showingExportSheet = false
                        }
                    }
                }
            }
        }

        private func calculateStorageSize() {
            DispatchQueue.global(qos: .utility).async {
                guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                else {
                    return
                }

                let size = try? FileManager.default.allocatedSizeOfDirectory(at: documentsPath)
                let sizeInMB = Double(size ?? 0) / 1_048_576

                DispatchQueue.main.async {
                    if sizeInMB < 1 {
                        storageSize = String(format: "%.1f KB", sizeInMB * 1024)
                    } else {
                        storageSize = String(format: "%.1f MB", sizeInMB)
                    }
                }
            }
        }

        private func updateStorageLocation() {
            if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                storageLocation = documentsPath.path
            }
        }

        private func clearCache() {
            // Clear URLCache
            URLCache.shared.removeAllCachedResponses()

            // Clear temp directory
            let tmpDirectory = FileManager.default.temporaryDirectory
            try? FileManager.default.contentsOfDirectory(at: tmpDirectory, includingPropertiesForKeys: nil)
                .forEach { url in
                    try? FileManager.default.removeItem(at: url)
                }

            // Recalculate storage and refresh location
            calculateStorageSize()
            updateStorageLocation()
        }

        @MainActor private func performExport() async {
            guard !isExporting else { return }
            isExporting = true
            defer { isExporting = false }

            guard let coursesStore = CoursesStore.shared else {
                exportError = NSLocalizedString(
                    "settings.storage.export.error.data",
                    value: "Unable to gather course data for export.",
                    comment: "Export data error"
                )
                return
            }

            let assignments = AssignmentsStore.shared.tasks

            let payload = StorageDataExport(
                exportedAt: Date(),
                tasks: exportIncludeTasks ? assignments : nil,
                semesters: exportIncludeSemesters ? coursesStore.semesters : nil,
                courses: exportIncludeCourses ? coursesStore.courses : nil,
                scheduledSessions: exportIncludePlannerSessions ? PlannerStore.shared.scheduled : nil,
                overflowSessions: exportIncludePlannerSessions ? PlannerStore.shared.overflow : nil,
                settings: exportIncludeSettings ? AppSettingsModel.shared : nil
            )

            do {
                let data = try JSONEncoder().encode(payload)
                let targetURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("itori-data-export-\(Int(Date().timeIntervalSince1970)).json")
                try data.write(to: targetURL, options: .atomic)
                exportError = nil
                showingExportSheet = false
                shareItem = ShareItem(url: targetURL)
            } catch {
                exportError = error.localizedDescription
            }
        }
    }

    private struct StorageDataExport: Codable {
        let exportedAt: Date
        let tasks: [AppTask]?
        let semesters: [Semester]?
        let courses: [Course]?
        let scheduledSessions: [StoredScheduledSession]?
        let overflowSessions: [StoredOverflowSession]?
        let settings: AppSettingsModel?
    }

    private struct ShareItem: Identifiable {
        let id = UUID()
        let url: URL
    }

    private struct ShareSheet: UIViewControllerRepresentable {
        let items: [Any]
        let completion: () -> Void

        func makeUIViewController(context _: Context) -> UIActivityViewController {
            let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
            controller.completionWithItemsHandler = { _, _, _, _ in
                completion()
            }
            return controller
        }

        func updateUIViewController(_: UIActivityViewController, context _: Context) {}
    }

    extension FileManager {
        func allocatedSizeOfDirectory(at url: URL) throws -> Int64 {
            let enumerator = enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey])
            var total: Int64 = 0

            while let fileURL = enumerator?.nextObject() as? URL {
                let values = try fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
                total += Int64(values.totalFileAllocatedSize ?? 0)
            }

            return total
        }
    }

    #if !DISABLE_PREVIEWS
        #Preview {
            NavigationStack {
                IOSStorageSettingsView()
                    .environmentObject(AppSettingsModel.shared)
            }
        }
    #endif
#endif
