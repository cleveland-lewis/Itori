internal import CoreData
import Combine
import Foundation
#if canImport(Network)
    import Network
#endif

struct GradeEntry: Identifiable, Codable, Hashable {
    var id: UUID { courseId }
    let courseId: UUID
    var percent: Double?
    var letter: String?
    var updatedAt: Date
}

@MainActor
final class GradesStore: ObservableObject {
    static let shared = GradesStore()

    @Published var isLoading: Bool = true
    @Published private(set) var grades: [GradeEntry] = []

    private let storageURL: URL
    private var iCloudMonitor: Timer?
    private var pathMonitor: NWPathMonitor?
    private var isOnline: Bool = true
    private var pendingSyncQueue: [GradeEntry] = []
    private var isLoadingFromDisk: Bool = false
    private var iCloudToggleObserver: NSObjectProtocol?

    private lazy var iCloudURL: URL? = {
        let containerIdentifier = "iCloud.com.cwlewisiii.Itori"
        guard let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier) else {
            return nil
        }
        let documentsURL = ubiquityURL.appendingPathComponent("Documents/Grades")
        try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        return documentsURL.appendingPathComponent("grades.json")
    }()

    private lazy var iCloudConflictsURL: URL? = {
        guard let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.com.cwlewisiii.Itori")
        else {
            return nil
        }
        let conflictsFolder = ubiquityURL.appendingPathComponent("Documents/Grades")
        try? FileManager.default.createDirectory(at: conflictsFolder, withIntermediateDirectories: true)
        return conflictsFolder
    }()

    private var conflictsFolderURL: URL? = {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        else { return nil }
        let folder = dir.appendingPathComponent("ItoriGrades/Conflicts", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }()

    private var isSyncEnabled: Bool {
        AppSettingsModel.shared.enableICloudSync
    }

    private init() {
        let fm = FileManager.default
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = dir.appendingPathComponent("ItoriGrades", isDirectory: true)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        self.storageURL = folder.appendingPathComponent("grades.json")

        // Skip slow initialization during tests
        guard !TestMode.isRunningTests else {
            isLoading = false
            return
        }

        // OPTIMIZATION: Defer all I/O to async initialization
        Task { @MainActor in
            await initializeAsync()
        }
    }

    // OPTIMIZATION: Async initialization to avoid blocking app launch
    @MainActor
    private func initializeAsync() async {
        // Step 1: Load data off-main thread
        await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await self.load()
        }.value

        // Step 2: Setup services
        setupNetworkMonitoring()
        observeICloudToggle()

        // Step 3: Load from iCloud if needed (deferred)
        await Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            await MainActor.run {
                self.loadFromiCloudIfEnabled()
                self.setupiCloudMonitoring()
            }
        }.value

        isLoading = false
    }

    func grade(for courseId: UUID) -> GradeEntry? {
        grades.first { $0.courseId == courseId }
    }

    func upsert(courseId: UUID, percent: Double?, letter: String?) {
        let now = Date()
        if let idx = grades.firstIndex(where: { $0.courseId == courseId }) {
            grades[idx].percent = percent
            grades[idx].letter = letter
            grades[idx].updatedAt = now
        } else {
            grades.append(GradeEntry(courseId: courseId, percent: percent, letter: letter, updatedAt: now))
        }
        save()

        // Sync to iCloud if enabled
        if isOnline && isSyncEnabled {
            saveToiCloud()
        }
    }

    func remove(courseId: UUID) {
        grades.removeAll { $0.courseId == courseId }
        save()

        // Sync to iCloud if enabled
        if isOnline && isSyncEnabled {
            saveToiCloud()
        }
    }

    func resetAll() {
        grades.removeAll()
        try? FileManager.default.removeItem(at: storageURL)
        save()

        // Sync to iCloud if enabled
        if isOnline && isSyncEnabled {
            saveToiCloud()
        }
    }

    private func save() {
        guard !isLoadingFromDisk else { return }

        do {
            let data = try JSONEncoder().encode(grades)
            try data.write(to: storageURL, options: [.atomic])

            // Sync to CoreData if enabled
            Task.detached(priority: .utility) { [weak self] in
                guard let self else { return }
                await self.syncToCoreData()
            }
        } catch {
            debugLog("Failed to save grades: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try JSONDecoder().decode([GradeEntry].self, from: data)
            grades = decoded
        } catch {
            debugLog("Failed to load grades: \(error)")
        }
    }

    // MARK: - CoreData Sync

    private func syncToCoreData() async {
        guard AppSettingsModel.shared.enableCoreDataSync else { return }

        let context = PersistenceController.shared.newBackgroundContext()
        let repo = GradeRepository(context: context)

        await context.perform {
            do {
                // Delete grades not in current set
                let existingGrades = repo.fetchAll()
                let currentCourseIds = Set(self.grades.map(\.courseId))
                for grade in existingGrades where !currentCourseIds.contains(grade.courseId) {
                    try repo.delete(grade)
                }

                // Save/update all current grades
                for grade in self.grades {
                    try repo.save(grade)
                }

                LOG_DATA(.debug, "GradesSync", "CoreData sync complete: \(self.grades.count) grades")
            } catch {
                LOG_DATA(.error, "GradesSync", "CoreData sync failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - iCloud Sync

    private func setupNetworkMonitoring() {
        pathMonitor = NWPathMonitor()
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isOnline = path.status == .satisfied
                if path.status == .satisfied, let self, self.isSyncEnabled {
                    self.saveToiCloud()
                }
            }
        }
        pathMonitor?.start(queue: DispatchQueue.global(qos: .background))
    }

    private func setupiCloudMonitoring() {
        guard isSyncEnabled else { return }
        iCloudMonitor = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.loadFromiCloud()
            }
        }
    }

    private func observeICloudToggle() {
        iCloudToggleObserver = NotificationCenter.default.addObserver(
            forName: .iCloudSyncSettingChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.isSyncEnabled {
                    self.setupiCloudMonitoring()
                    self.loadFromiCloudIfEnabled()
                } else {
                    self.iCloudMonitor?.invalidate()
                    self.iCloudMonitor = nil
                }
            }
        }
    }

    private func loadFromiCloudIfEnabled() {
        guard isSyncEnabled else { return }
        Task {
            await loadFromiCloud()
        }
    }

    private func loadFromiCloud() async {
        guard let iCloudURL else { return }

        do {
            let coordinator = NSFileCoordinator()
            var error: NSError?
            var cloudData: Data?

            coordinator.coordinate(readingItemAt: iCloudURL, options: [], error: &error) { url in
                cloudData = try? Data(contentsOf: url)
            }

            if let error {
                debugLog("iCloud read error: \(error)")
                return
            }

            guard let data = cloudData else { return }

            let cloudGrades = try JSONDecoder().decode([GradeEntry].self, from: data)

            if cloudGrades != grades {
                isLoadingFromDisk = true
                grades = cloudGrades
                isLoadingFromDisk = false
                save()
                debugLog("✅ Loaded \(cloudGrades.count) grades from iCloud")
            }
        } catch {
            debugLog("Failed to load from iCloud: \(error)")
        }
    }

    private func saveToiCloud() {
        guard let iCloudURL, isSyncEnabled else { return }

        Task.detached(priority: .utility) {
            do {
                let data = try await JSONEncoder().encode(self.grades)
                let coordinator = NSFileCoordinator()
                var error: NSError?

                coordinator.coordinate(writingItemAt: iCloudURL, options: .forReplacing, error: &error) { url in
                    try? data.write(to: url, options: [.atomic])
                }

                if let error {
                    await self.debugLog("iCloud write error: \(error)")
                }
            } catch {
                await self.debugLog("Failed to save to iCloud: \(error)")
            }
        }
    }

    private func trackPendingChanges() {
        pendingSyncQueue = grades
    }

    deinit {
        iCloudMonitor?.invalidate()
        pathMonitor?.cancel()
        if let observer = iCloudToggleObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func debugLog(_ message: String) {
        guard AppSettingsModel.shared.devModeDataLogging else { return }
        DebugLogger.log(message)
    }
}
