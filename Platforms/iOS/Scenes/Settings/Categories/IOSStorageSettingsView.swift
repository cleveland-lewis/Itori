import SwiftUI
#if os(iOS)

    import UIKit

    struct IOSStorageSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel
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
        @State private var exportError: String?
        @State private var statusLabel: String = NSLocalizedString(
            "settings.storage.status.disconnected",
            value: "Disconnected",
            comment: "Storage status disconnected"
        )
        @State private var syncTimeoutWorkItem: DispatchWorkItem?
        #if DEBUG
            @StateObject private var syncMonitor = SyncMonitor.shared
        #endif

        var body: some View {
            List {
                Section {
                    HStack {
                        Text(NSLocalizedString("settings.storage.used", comment: "Storage Used"))
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
                    Text(NSLocalizedString("settings.storage.info.header", comment: "Storage"))
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
                    Text(NSLocalizedString("settings.privacy.data.header", comment: "Data Storage"))
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

                #if DEBUG
                    Section {
                        HStack {
                            Text(NSLocalizedString(
                                "settings.storage.debug.cloudkit",
                                value: "CloudKit",
                                comment: "CloudKit debug label"
                            ))
                            Spacer()
                            Text(syncMonitor.isCloudKitActive
                                ? NSLocalizedString(
                                    "settings.storage.debug.active",
                                    value: "Active",
                                    comment: "CloudKit active"
                                )
                                : NSLocalizedString(
                                    "settings.storage.debug.inactive",
                                    value: "Inactive",
                                    comment: "CloudKit inactive"
                                ))
                                .foregroundColor(syncMonitor.isCloudKitActive ? .green : .secondary)
                        }
                        if let lastSync = syncMonitor.lastRemoteChange {
                            HStack {
                                Text(NSLocalizedString(
                                    "settings.storage.debug.last_sync",
                                    value: "Last Sync",
                                    comment: "CloudKit last sync label"
                                ))
                                Spacer()
                                Text(lastSync.formatted(.relative(presentation: .numeric)))
                                    .foregroundColor(.secondary)
                            }
                        }
                        if let lastError = syncMonitor.lastError {
                            HStack(alignment: .top) {
                                Text(NSLocalizedString(
                                    "settings.storage.debug.last_error",
                                    value: "Last Error",
                                    comment: "CloudKit last error label"
                                ))
                                Spacer()
                                Text(lastError)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        if let latest = syncMonitor.syncEvents.first {
                            HStack(alignment: .top) {
                                Text(NSLocalizedString(
                                    "settings.storage.debug.latest_event",
                                    value: "Latest Event",
                                    comment: "CloudKit latest event label"
                                ))
                                Spacer()
                                Text(latest.details)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    } header: {
                        Text(NSLocalizedString(
                            "settings.storage.debug.header",
                            value: "iCloud Debug",
                            comment: "CloudKit debug header"
                        ))
                    } footer: {
                        Text(NSLocalizedString(
                            "settings.storage.debug.footer",
                            value: "Debug-only iCloud status and recent sync activity.",
                            comment: "CloudKit debug footer"
                        ))
                    }
                #endif

                Section {
                    Button {
                        showingClearCacheConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text(NSLocalizedString("settings.storage.clear_cache", comment: "Clear Cache"))
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
                    Text(NSLocalizedString("settings.storage.maintenance.header", comment: "Maintenance"))
                } footer: {
                    Text(NSLocalizedString(
                        "settings.storage.maintenance.footer",
                        comment: "Clearing cache can free up storage space and may improve performance"
                    ))
                }

                Section {
                    Button {
                        showingExportSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text(NSLocalizedString("settings.storage.export", comment: "Export Data"))
                        }
                    }
                } header: {
                    Text(NSLocalizedString("settings.storage.backup.header", comment: "Backup"))
                } footer: {
                    Text(NSLocalizedString(
                        "settings.storage.backup.footer",
                        comment: "Export your data as a backup file"
                    ))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(NSLocalizedString("settings.category.storage", comment: "Storage"))
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
                VStack(spacing: 20) {
                    Image(systemName: "square.and.arrow.up.circle")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .foregroundColor(.accentColor)

                    Text(NSLocalizedString("settings.storage.export.title", comment: "Export Data"))
                        .font(.title2.weight(.semibold))

                    Text(NSLocalizedString(
                        "settings.storage.export.message",
                        comment: "Your data will be exported as a JSON file that you can save or share."
                    ))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
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
                            Text(NSLocalizedString("settings.storage.export.button", comment: "Export Now"))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.itoriLiquidProminent)
                    .padding(.horizontal)
                    .disabled(isExporting)
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

            let assignments = AssignmentsStore.shared.tasks
            guard let coursesStore = CoursesStore.shared else {
                exportError = NSLocalizedString(
                    "settings.storage.export.error.data",
                    value: "Unable to gather course data for export.",
                    comment: "Export data error"
                )
                return
            }

            let payload = StorageDataExport(
                exportedAt: Date(),
                tasks: assignments,
                semesters: coursesStore.semesters,
                courses: coursesStore.courses,
                scheduledSessions: PlannerStore.shared.scheduled,
                overflowSessions: PlannerStore.shared.overflow,
                settings: AppSettingsModel.shared
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
        let tasks: [AppTask]
        let semesters: [Semester]
        let courses: [Course]
        let scheduledSessions: [StoredScheduledSession]
        let overflowSessions: [StoredOverflowSession]
        let settings: AppSettingsModel
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
