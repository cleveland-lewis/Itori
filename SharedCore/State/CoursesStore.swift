import Foundation
import SwiftUI
import Combine
import Network

private struct CoursesPersistedData: Codable {
    var semesters: [Semester]
    var courses: [Course]
    var outlineNodes: [CourseOutlineNode]
    var courseFiles: [CourseFile]
    var currentSemesterId: UUID?
    var activeSemesterIds: [UUID]?  // New: multi-semester support
    
    // Custom decoding to handle backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        semesters = try container.decode([Semester].self, forKey: .semesters)
        courses = try container.decode([Course].self, forKey: .courses)
        // Provide default empty array if outlineNodes is missing (backward compatibility)
        outlineNodes = try container.decodeIfPresent([CourseOutlineNode].self, forKey: .outlineNodes) ?? []
        courseFiles = try container.decodeIfPresent([CourseFile].self, forKey: .courseFiles) ?? []
        currentSemesterId = try container.decodeIfPresent(UUID.self, forKey: .currentSemesterId)
        activeSemesterIds = try container.decodeIfPresent([UUID].self, forKey: .activeSemesterIds)
    }
    
    // Memberwise init for encoding
    init(
        semesters: [Semester],
        courses: [Course],
        outlineNodes: [CourseOutlineNode],
        courseFiles: [CourseFile],
        currentSemesterId: UUID?,
        activeSemesterIds: Set<UUID>
    ) {
        self.semesters = semesters
        self.courses = courses
        self.outlineNodes = outlineNodes
        self.courseFiles = courseFiles
        self.currentSemesterId = currentSemesterId
        self.activeSemesterIds = Array(activeSemesterIds)
    }
}

@MainActor
final class CoursesStore: ObservableObject {
    static weak var shared: CoursesStore?
    // Publishes course deleted events
    fileprivate let courseDeleted = PassthroughSubject<UUID, Never>()

    @Published private(set) var semesters: [Semester] = []
    @Published private(set) var courses: [Course] = []
    @Published private(set) var outlineNodes: [CourseOutlineNode] = []
    @Published private(set) var courseFiles: [CourseFile] = []
    @Published private(set) var currentGPA: Double = 0

    // MARK: - Active Semesters (Multi-semester support)
    
    @Published var activeSemesterIds: Set<UUID> = [] {
        didSet {
            persist()
        }
    }
    
    // Legacy support: currentSemesterId for backward compatibility
    @Published var currentSemesterId: UUID? {
        didSet {
            // Migrate: if currentSemesterId is set, ensure it's in activeSemesterIds
            if let id = currentSemesterId, !activeSemesterIds.contains(id) {
                activeSemesterIds = [id]
            }
            markCurrentSemester(currentSemesterId)
            persist()
        }
    }

    private let storageURL: URL
    private let cacheURL: URL
    private var iCloudMonitor: Timer?
    private var pathMonitor: NWPathMonitor?
    private var isOnline: Bool = true
    private var isLoadingFromDisk: Bool = false
    private var iCloudToggleObserver: NSObjectProtocol?
    private var hasLoadedFromiCloud: Bool = false
    private var pendingCloudConflict: CoursesPersistedData?
    
    // OPTIMIZATION: Track loading state for UI
    @Published private(set) var isInitialLoadComplete: Bool = false
    
    // PHASE 2: Snapshot structure for off-main loading
    private struct InitialCoursesSnapshot {
        let semesters: [Semester]
        let courses: [Course]
        let outlineNodes: [CourseOutlineNode]
        let courseFiles: [CourseFile]
        let currentSemesterId: UUID?
        let activeSemesterIds: Set<UUID>
        let computedGPA: Double
    }

    init(storageURL: URL? = nil) {
        let fm = FileManager.default
        if let storageURL = storageURL {
            self.storageURL = storageURL
            // ensure containing directory exists
            try? fm.createDirectory(at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        } else {
            let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let folder = dir.appendingPathComponent("RootsCourses", isDirectory: true)
            try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
            self.storageURL = folder.appendingPathComponent("courses.json")
        }
        let cacheFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("RootsCourses", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        self.cacheURL = cacheFolder.appendingPathComponent("courses_cache.json")

        // OPTIMIZATION: Setup only - defer actual data loading
        // Skip slow initialization during tests
        guard !TestMode.isRunningTests else {
            CoursesStore.shared = self
            return
        }
        
        setupNetworkMonitoring()
        observeICloudToggle()
        CoursesStore.shared = self
        
        // OPTIMIZATION: Load data asynchronously after initialization
        Task { @MainActor in
            await loadDataAsync()
        }
    }
    
    // OPTIMIZATION: Async data loading - doesn't block app launch
    // PHASE 2: Moved heavy work off MainActor
    private func loadDataAsync() async {
        // PHASE 2: Perform ALL disk I/O, decoding, and computation OFF main thread
        let snapshot = await Task.detached(priority: .userInitiated) { [weak self] () -> InitialCoursesSnapshot? in
            guard let self = self else { return nil }
            
            let startTime = CFAbsoluteTimeGetCurrent()
            await LOG_PERSISTENCE(.debug, "CoursesLoad", "Starting off-main data load")
            
            // Step 1: Load cache (fast path)
            var semesters: [Semester] = []
            var courses: [Course] = []
            var outlineNodes: [CourseOutlineNode] = []
            var courseFiles: [CourseFile] = []
            var currentSemesterId: UUID?
            var activeSemesterIds: Set<UUID> = []
            
            // Load cache first (if available)
            if FileManager.default.fileExists(atPath: self.cacheURL.path) {
                do {
                    let data = try Data(contentsOf: self.cacheURL)
                    let decoded = try JSONDecoder().decode(CoursesPersistedData.self, from: data)
                    semesters = decoded.semesters
                    courses = decoded.courses
                    outlineNodes = decoded.outlineNodes
                    courseFiles = decoded.courseFiles
                    currentSemesterId = decoded.currentSemesterId
                    activeSemesterIds = decoded.activeSemesterIds.map { Set($0) } ?? (currentSemesterId.map { [$0] } ?? [])
                    await LOG_PERSISTENCE(.debug, "CoursesCache", "Loaded cache off-main", metadata: ["semesters": "\(semesters.count)"])
                } catch {
                    await LOG_PERSISTENCE(.error, "CoursesCache", "Cache load failed: \(error.localizedDescription)")
                }
            }
            
            // Step 2: Load main storage (may override cache)
            if FileManager.default.fileExists(atPath: self.storageURL.path) {
                do {
                    let data = try Data(contentsOf: self.storageURL)
                    let decoded = try JSONDecoder().decode(CoursesPersistedData.self, from: data)
                    semesters = decoded.semesters
                    courses = decoded.courses
                    outlineNodes = decoded.outlineNodes
                    courseFiles = decoded.courseFiles
                    currentSemesterId = decoded.currentSemesterId
                    activeSemesterIds = decoded.activeSemesterIds.map { Set($0) } ?? (currentSemesterId.map { [$0] } ?? [])
                    await LOG_PERSISTENCE(.debug, "CoursesLoad", "Loaded main storage off-main", metadata: ["semesters": "\(semesters.count)"])
                } catch {
                    await LOG_PERSISTENCE(.error, "CoursesLoad", "Storage load failed: \(error.localizedDescription)")
                }
            }
            
            // Step 3: Cleanup old data (off-main)
            let threshold = Date().addingTimeInterval(-30 * 24 * 60 * 60)
            let expiredIds = semesters.compactMap { semester -> UUID? in
                guard let deletedAt = semester.deletedAt, deletedAt < threshold else { return nil }
                return semester.id
            }
            if !expiredIds.isEmpty {
                semesters.removeAll { expiredIds.contains($0.id) }
                courses.removeAll { expiredIds.contains($0.semesterId) }
                if let currentId = currentSemesterId, expiredIds.contains(currentId) {
                    currentSemesterId = nil
                }
                await LOG_PERSISTENCE(.debug, "CoursesCleanup", "Cleaned \(expiredIds.count) expired items off-main")
            }
            
            // Step 4: Compute GPA off-main (expensive!)
            _ = courses.filter { !$0.isArchived }
            // Note: GPA calculation needs tasks, but we'll defer that to avoid circular dependency
            // For now, compute basic GPA structure
            let gpa = 0.0  // Will be computed properly on main thread after merge
            
            let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            await LOG_PERSISTENCE(.info, "CoursesLoad", "Off-main load complete in \(Int(elapsed))ms")
            
            return InitialCoursesSnapshot(
                semesters: semesters,
                courses: courses,
                outlineNodes: outlineNodes,
                courseFiles: courseFiles,
                currentSemesterId: currentSemesterId,
                activeSemesterIds: activeSemesterIds,
                computedGPA: gpa
            )
        }.value
        
        // PHASE 2: Apply snapshot on main thread in ONE batch
        guard let snapshot = snapshot else {
            LOG_PERSISTENCE(.error, "CoursesLoad", "Failed to load snapshot")
            isInitialLoadComplete = true
            return
        }
        
        await MainActor.run {
            LOG_PERSISTENCE(.debug, "CoursesLoad", "Applying snapshot on main thread")
            
            // Single batch update - triggers @Published ONCE
            self.semesters = snapshot.semesters
            self.courses = snapshot.courses
            self.outlineNodes = snapshot.outlineNodes
            self.courseFiles = snapshot.courseFiles
            self.currentSemesterId = snapshot.currentSemesterId
            self.activeSemesterIds = snapshot.activeSemesterIds
            self.currentGPA = snapshot.computedGPA
            
            // SAFETY: Ensure activeSemesterIds is never empty if there are active semesters
            if self.activeSemesterIds.isEmpty {
                // Try current semester first
                if let currentId = self.currentSemesterId, !self.isDeleted(semesterId: currentId) {
                    self.activeSemesterIds = [currentId]
                    LOG_PERSISTENCE(.info, "CoursesLoad", "Initialized activeSemesterIds from currentSemesterId")
                }
                // Fallback to most recent non-archived, non-deleted semester
                else if let mostRecent = self.semesters
                    .filter({ !$0.isArchived && !self.isDeleted(semesterId: $0.id) })
                    .sorted(by: { $0.startDate > $1.startDate })
                    .first {
                    self.activeSemesterIds = [mostRecent.id]
                    LOG_PERSISTENCE(.info, "CoursesLoad", "Initialized activeSemesterIds to most recent semester")
                }
            }
            
            LOG_PERSISTENCE(.info, "CoursesLoad", "Initial load complete - data published")
        }
        
        // PHASE 2: Defer iCloud and expensive operations
        await loadFromiCloudIfEnabledAsync()
        
        // PHASE 2: Setup monitoring after data is loaded
        await MainActor.run {
            setupiCloudMonitoring()
            isInitialLoadComplete = true
            LOG_PERSISTENCE(.info, "CoursesLoad", "All initialization complete")
        }
        
        // PHASE 2: Compute GPA async after UI is interactive
        Task.detached(priority: .utility) { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            guard let self = self else { return }
            let tasks = await AssignmentsStore.shared.tasks
            let gradedCourses = await self.courses.filter { !$0.isArchived }
            let gpa = await GradeCalculator.calculateGPA(courses: gradedCourses, tasks: tasks)
            await MainActor.run {
                self.currentGPA = gpa
                LOG_PERSISTENCE(.debug, "CoursesGPA", "GPA computed async: \(gpa)")
            }
        }
    }
    
    private lazy var iCloudURL: URL? = {
        let containerIdentifier = "iCloud.com.cwlewisiii.Itori"
        guard let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier) else {
            return nil
        }
        let documentsURL = ubiquityURL.appendingPathComponent("Documents/Courses")
        try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        return documentsURL.appendingPathComponent("courses.json")
    }()
    
    private var isSyncEnabled: Bool {
        AppSettingsModel.shared.enableICloudSync
    }

    // MARK: - Public API
    
    // MARK: - Helper Methods
    
    /// Check if a semester is soft-deleted
    private func isDeleted(semesterId: UUID) -> Bool {
        return semesters.first(where: { $0.id == semesterId })?.deletedAt != nil
    }

    // Legacy single semester support
    var currentSemester: Semester? {
        guard let id = currentSemesterId else { return nil }
        return semesters.first(where: { $0.id == id && $0.deletedAt == nil })
    }

    var currentSemesterCourses: [Course] {
        guard let id = currentSemesterId else { return [] }
        return courses.filter { $0.semesterId == id }
    }
    
    
    /// Toggle a semester's active state
    func toggleActiveSemester(_ semester: Semester) {
        if activeSemesterIds.contains(semester.id) {
            activeSemesterIds.remove(semester.id)
        } else {
            activeSemesterIds.insert(semester.id)
        }
        
        // Keep currentSemesterId in sync (use first active or nil)
        if activeSemesterIds.isEmpty {
            currentSemesterId = nil
        } else if let current = currentSemesterId, !activeSemesterIds.contains(current) {
            currentSemesterId = activeSemesterIds.first
        } else if currentSemesterId == nil {
            currentSemesterId = activeSemesterIds.first
        }
    }
    
    /// Set multiple active semesters at once
    func setActiveSemesters(_ semesterIds: Set<UUID>) {
        activeSemesterIds = semesterIds
        
        // Sync currentSemesterId
        if activeSemesterIds.isEmpty {
            currentSemesterId = nil
        } else if let current = currentSemesterId, !activeSemesterIds.contains(current) {
            currentSemesterId = activeSemesterIds.first
        } else if currentSemesterId == nil {
            currentSemesterId = activeSemesterIds.first
        }
    }
    
    /// Get courses for a specific semester
    func courses(in semester: Semester) -> [Course] {
        courses.filter { $0.semesterId == semester.id && !$0.isArchived }
    }
    
    /// Get all non-archived courses, optionally filtered to active semesters only
    func getAllCourses(activeOnly: Bool = false) -> [Course] {
        if activeOnly {
            return activeCourses
        } else {
            return courses.filter { !$0.isArchived }
        }
    }

    func addSemester(_ semester: Semester) {
        semesters.append(semester)
        if semester.isCurrent {
            currentSemesterId = semester.id
            activeSemesterIds.insert(semester.id)
        }
        persist()
    }

    func setCurrentSemester(_ semester: Semester) {
        currentSemesterId = semester.id
        // Ensure current semester is in active set
        activeSemesterIds.insert(semester.id)
    }

    func toggleCurrentSemester(_ semester: Semester) {
        if semester.id == currentSemesterId {
            currentSemesterId = nil
        } else {
            setCurrentSemester(semester)
        }
    }

    func addCourse(title: String, code: String, to semester: Semester) {
        let newCourse = Course(title: title, code: code, semesterId: semester.id, isArchived: false)
        courses.append(newCourse)
        LOG_COURSES(.info, "CourseAdded", "Course added: \(title)", metadata: ["courseId": newCourse.id.uuidString, "semesterId": semester.id.uuidString])
        persist()
        recalcGPA(tasks: AssignmentsStore.shared.tasks)
    }

    func resetAll() {
        semesters.removeAll()
        courses.removeAll()
        outlineNodes.removeAll()
        courseFiles.removeAll()
        currentSemesterId = nil
        try? FileManager.default.removeItem(at: storageURL)
        try? FileManager.default.removeItem(at: cacheURL)
        persist()
        recalcGPA(tasks: AssignmentsStore.shared.tasks)
    }

    func addCourse(_ course: Course) {
        courses.append(course)
        persist()
        recalcGPA(tasks: AssignmentsStore.shared.tasks)
    }

    func updateCourse(_ course: Course) {
        guard let idx = courses.firstIndex(where: { $0.id == course.id }) else { return }
        courses[idx] = course
        persist()
        recalcGPA(tasks: AssignmentsStore.shared.tasks)
    }

    func toggleArchiveCourse(_ course: Course) {
        guard let idx = courses.firstIndex(where: { $0.id == course.id }) else { return }
        courses[idx].isArchived.toggle()
        persist()
        recalcGPA(tasks: AssignmentsStore.shared.tasks)
    }

    func deleteCourse(_ course: Course) {
        courses.removeAll { $0.id == course.id }
        AssignmentsStore.shared.reassignTasks(fromCourseId: course.id, toCourseId: nil)
        // Publish course deleted event via Combine for subscribers
        courseDeleted.send(course.id)
        persist()
        recalcGPA(tasks: AssignmentsStore.shared.tasks)
    }

    /// All courses across active semesters (respecting activeSemesterIds)
    var activeCourses: [Course] {
        if activeSemesterIds.isEmpty {
            // Fallback: show courses from current semester if no active semesters set
            if let currentId = currentSemesterId {
                return courses.filter { $0.semesterId == currentId && !$0.isArchived }
            }
            return courses.filter { !$0.isArchived }
        }
        return courses.filter { activeSemesterIds.contains($0.semesterId) && !$0.isArchived }
    }

    var archivedCourses: [Course] {
        courses.filter { $0.isArchived }
    }

    // MARK: - Semester Management

    func updateSemester(_ semester: Semester) {
        guard let idx = semesters.firstIndex(where: { $0.id == semester.id }) else { return }
        semesters[idx] = semester
        persist()
    }

    func toggleArchiveSemester(_ semester: Semester) {
        guard let idx = semesters.firstIndex(where: { $0.id == semester.id }) else { return }
        semesters[idx].isArchived.toggle()
        persist()
        recalcGPA(tasks: AssignmentsStore.shared.tasks)
    }

    func deleteSemester(_ id: UUID) {
        guard let idx = semesters.firstIndex(where: { $0.id == id }) else { return }
        semesters[idx].deletedAt = Date()
        semesters[idx].isCurrent = false
        if currentSemesterId == id {
            currentSemesterId = nil
        }
        activeSemesterIds.remove(id)
        persist()
        recalcGPA(tasks: AssignmentsStore.shared.tasks)
    }

    func recoverSemester(_ id: UUID) {
        guard let idx = semesters.firstIndex(where: { $0.id == id }) else { return }
        semesters[idx].deletedAt = nil
        persist()
        recalcGPA(tasks: AssignmentsStore.shared.tasks)
    }

    func permanentlyDeleteSemester(_ id: UUID) {
        semesters.removeAll { $0.id == id }
        courses.removeAll { $0.semesterId == id }
        if currentSemesterId == id {
            currentSemesterId = nil
        }
        activeSemesterIds.remove(id)
        persist()
        recalcGPA(tasks: AssignmentsStore.shared.tasks)
    }

    var nonArchivedSemesters: [Semester] {
        semesters.filter { !$0.isArchived && $0.deletedAt == nil }.sorted { $0.startDate > $1.startDate }
    }
    
    /// All semesters marked as active (supports multiple concurrent semesters)
    var activeSemesters: [Semester] {
        semesters.filter { activeSemesterIds.contains($0.id) && $0.deletedAt == nil && !$0.isArchived }
    }

    var archivedSemesters: [Semester] {
        semesters.filter { $0.isArchived && $0.deletedAt == nil }.sorted { $0.startDate > $1.startDate }
    }

    var recentlyDeletedSemesters: [Semester] {
        semesters.compactMap { $0.deletedAt == nil ? nil : $0 }.sorted { ($0.deletedAt ?? Date.distantPast) > ($1.deletedAt ?? Date.distantPast) }
    }

    var futureSemesters: [Semester] {
        let now = Date()
        return semesters.filter { !$0.isArchived && $0.deletedAt == nil && $0.startDate > now }.sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            LOG_PERSISTENCE(.info, "CoursesLoad", "No persisted courses data found")
            return
        }
        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try JSONDecoder().decode(CoursesPersistedData.self, from: data)
            self.semesters = decoded.semesters
            self.courses = decoded.courses
            self.outlineNodes = decoded.outlineNodes
            self.courseFiles = decoded.courseFiles
            self.currentSemesterId = decoded.currentSemesterId
            
            // Migration: populate activeSemesterIds from currentSemesterId if needed
            if let activeSemesterIdsArray = decoded.activeSemesterIds {
                self.activeSemesterIds = Set(activeSemesterIdsArray)
            } else if let currentId = decoded.currentSemesterId {
                // Migrate old data: current semester becomes the only active semester
                self.activeSemesterIds = [currentId]
            } else {
                self.activeSemesterIds = []
            }
            
            LOG_PERSISTENCE(.info, "CoursesLoad", "Loaded courses data", metadata: ["semesters": "\(semesters.count)", "courses": "\(courses.count)", "activeSemesters": "\(activeSemesterIds.count)"])
        } catch {
            LOG_PERSISTENCE(.error, "CoursesLoad", "Failed to decode courses data: \(error.localizedDescription)")
        }
    }

    private func loadCache() {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            LOG_PERSISTENCE(.debug, "CoursesCache", "No cache file found")
            return
        }
        do {
            let data = try Data(contentsOf: cacheURL)
            let decoded = try JSONDecoder().decode(CoursesPersistedData.self, from: data)
            self.semesters = decoded.semesters
            self.courses = decoded.courses
            self.outlineNodes = decoded.outlineNodes
            self.courseFiles = decoded.courseFiles
            self.currentSemesterId = decoded.currentSemesterId
            
            // Migration for activeSemesterIds
            if let activeSemesterIdsArray = decoded.activeSemesterIds {
                self.activeSemesterIds = Set(activeSemesterIdsArray)
            } else if let currentId = decoded.currentSemesterId {
                self.activeSemesterIds = [currentId]
            }
            
            LOG_PERSISTENCE(.debug, "CoursesCache", "Loaded cache", metadata: ["semesters": "\(semesters.count)", "courses": "\(courses.count)"])
        } catch {
            LOG_PERSISTENCE(.error, "CoursesCache", "Failed to load cache: \(error.localizedDescription)")
        }
    }

    private func persist() {
        guard !isLoadingFromDisk else { return }
        
        let snapshot = CoursesPersistedData(
            semesters: semesters,
            courses: courses,
            outlineNodes: outlineNodes,
            courseFiles: courseFiles,
            currentSemesterId: currentSemesterId,
            activeSemesterIds: activeSemesterIds
        )
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: storageURL, options: [Data.WritingOptions.atomic, Data.WritingOptions.completeFileProtection])
            try data.write(to: cacheURL, options: [Data.WritingOptions.atomic, Data.WritingOptions.completeFileProtection])
            LOG_PERSISTENCE(.debug, "CoursesSave", "Persisted courses data", metadata: ["semesters": "\(semesters.count)", "courses": "\(courses.count)", "activeSemesters": "\(activeSemesterIds.count)", "size": "\(data.count)"])
            
            // Queue for iCloud sync if online and enabled
            if isOnline && isSyncEnabled {
                saveToiCloud()
            }
        } catch {
            LOG_PERSISTENCE(.error, "CoursesSave", "Failed to persist courses data: \(error.localizedDescription)")
        }
    }

    // MARK: - GPA recalculation

    @MainActor
    func recalcGPA(tasks: [AppTask]) {
        let gradedCourses = courses.filter { !$0.isArchived }
        currentGPA = GradeCalculator.calculateGPA(courses: gradedCourses, tasks: tasks)
    }

    func cleanupOldData() {
        let threshold = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        let expiredIds = semesters.compactMap { semester -> UUID? in
            guard let deletedAt = semester.deletedAt, deletedAt < threshold else { return nil }
            return semester.id
        }

        guard !expiredIds.isEmpty else { return }

        semesters.removeAll { expiredIds.contains($0.id) }
        courses.removeAll { expiredIds.contains($0.semesterId) }
        if let currentId = currentSemesterId, expiredIds.contains(currentId) {
            currentSemesterId = nil
        }

        persist()
    }

    private func markCurrentSemester(_ id: UUID?) {
        semesters = semesters.map { semester in
            var s = semester
            let isTarget = semester.id == id
            s.isCurrent = isTarget && semester.deletedAt == nil
            return s
        }
    }
}

// MARK: - Course Outline Management

extension CoursesStore {
    /// Fetch all outline nodes for a specific course
    func outlineNodes(for courseId: UUID) -> [CourseOutlineNode] {
        outlineNodes.filter { $0.courseId == courseId }
    }
    
    /// Fetch root nodes (no parent) for a course, sorted by sortIndex
    func rootOutlineNodes(for courseId: UUID) -> [CourseOutlineNode] {
        outlineNodes
            .filter { $0.courseId == courseId && $0.parentId == nil }
            .sorted { $0.sortIndex < $1.sortIndex }
    }
    
    /// Fetch children of a specific parent node, sorted by sortIndex
    func childOutlineNodes(for parentId: UUID) -> [CourseOutlineNode] {
        outlineNodes
            .filter { $0.parentId == parentId }
            .sorted { $0.sortIndex < $1.sortIndex }
    }
    
    /// Add a new outline node
    func addOutlineNode(_ node: CourseOutlineNode) {
        var newNode = node
        newNode.createdAt = Date()
        newNode.updatedAt = Date()
        outlineNodes.append(newNode)
        persist()
    }
    
    /// Update an existing outline node
    func updateOutlineNode(_ node: CourseOutlineNode) {
        guard let index = outlineNodes.firstIndex(where: { $0.id == node.id }) else { return }
        var updatedNode = node
        updatedNode.updatedAt = Date()
        outlineNodes[index] = updatedNode
        persist()
    }
    
    /// Delete an outline node (single node only, orphans children)
    func deleteOutlineNode(_ id: UUID) {
        outlineNodes.removeAll { $0.id == id }
        persist()
    }
    
    /// Delete a node and all its descendants (cascade delete)
    func deleteSubtree(_ nodeId: UUID) {
        // Get all descendants to delete
        let descendantIds = getAllDescendants(of: nodeId)
        
        // Delete the node itself plus all descendants
        var idsToDelete = descendantIds
        idsToDelete.insert(nodeId)
        
        outlineNodes.removeAll { idsToDelete.contains($0.id) }
        persist()
    }
    
    /// Count how many nodes would be deleted (for UI confirmation)
    func countSubtreeNodes(_ nodeId: UUID) -> Int {
        let descendants = getAllDescendants(of: nodeId)
        return descendants.count + 1  // +1 for the node itself
    }
    
    // MARK: - Tree Validation
    
    /// Check if a node can be moved to a new parent without creating a cycle
    func canMoveNode(_ nodeId: UUID, to newParentId: UUID?) -> Bool {
        // Moving to root is always safe
        guard let newParentId = newParentId else { return true }
        
        // Cannot move to itself
        if nodeId == newParentId { return false }
        
        // Cannot move to any of its descendants (would create cycle)
        return !isDescendant(nodeId, of: newParentId)
    }
    
    /// Check if potentialDescendant is in the subtree of ancestorId
    private func isDescendant(_ potentialDescendant: UUID, of ancestorId: UUID) -> Bool {
        // Get all descendants of ancestorId
        let descendants = getAllDescendants(of: ancestorId)
        return descendants.contains(potentialDescendant)
    }
    
    /// Get all descendants (children, grandchildren, etc.) of a node
    private func getAllDescendants(of nodeId: UUID) -> Set<UUID> {
        var descendants = Set<UUID>()
        var toProcess = [nodeId]
        
        while !toProcess.isEmpty {
            let currentId = toProcess.removeFirst()
            let children = outlineNodes.filter { $0.parentId == currentId }
            
            for child in children {
                descendants.insert(child.id)
                toProcess.append(child.id)
            }
        }
        
        return descendants
    }
    
    /// Safely move a node to a new parent (with validation)
    func moveNodeToParent(_ nodeId: UUID, newParentId: UUID?) -> Bool {
        guard canMoveNode(nodeId, to: newParentId) else { return false }
        
        guard let index = outlineNodes.firstIndex(where: { $0.id == nodeId }) else { return false }
        
        let oldParentId = outlineNodes[index].parentId
        
        // Remove from old siblings and reindex
        if oldParentId != newParentId {
            reindexSiblings(parentId: oldParentId)
        }
        
        var node = outlineNodes[index]
        node.parentId = newParentId
        
        // Place at end of new siblings
        let siblings = outlineNodes.filter { $0.parentId == newParentId && $0.id != nodeId }
        node.sortIndex = siblings.isEmpty ? 0 : (siblings.map { $0.sortIndex }.max() ?? 0) + 1
        node.updatedAt = Date()
        
        outlineNodes[index] = node
        persist()
        
        return true
    }
    
    // MARK: - SortIndex Management
    
    /// Reindex all siblings to have sequential sortIndex (0, 1, 2, ...)
    func reindexSiblings(parentId: UUID?) {
        let siblings = outlineNodes
            .filter { $0.parentId == parentId }
            .sorted { $0.sortIndex < $1.sortIndex }
        
        for (index, sibling) in siblings.enumerated() {
            if let nodeIndex = outlineNodes.firstIndex(where: { $0.id == sibling.id }) {
                outlineNodes[nodeIndex].sortIndex = index
            }
        }
        persist()
    }
    
    /// Move a node to a specific position within its siblings
    func moveNode(_ nodeId: UUID, toPosition position: Int) {
        guard let nodeIndex = outlineNodes.firstIndex(where: { $0.id == nodeId }) else { return }
        
        let node = outlineNodes[nodeIndex]
        let siblings = outlineNodes
            .filter { $0.parentId == node.parentId && $0.id != nodeId }
            .sorted { $0.sortIndex < $1.sortIndex }
        
        // Clamp position
        let targetPosition = max(0, min(position, siblings.count))
        
        // Rebuild sibling list with node at new position
        var newSiblings = siblings
        newSiblings.insert(node, at: targetPosition)
        
        // Update sortIndex for all affected nodes
        for (index, sibling) in newSiblings.enumerated() {
            if let idx = outlineNodes.firstIndex(where: { $0.id == sibling.id }) {
                outlineNodes[idx].sortIndex = index
                outlineNodes[idx].updatedAt = Date()
            }
        }
        
        persist()
    }
    
    /// Get next available sortIndex for a parent
    func nextSortIndex(for parentId: UUID?) -> Int {
        let siblings = outlineNodes.filter { $0.parentId == parentId }
        return siblings.isEmpty ? 0 : (siblings.map { $0.sortIndex }.max() ?? 0) + 1
    }
}

// MARK: - Course Files Management

extension CoursesStore {
    /// Get all files for a course
    func courseFiles(for courseId: UUID) -> [CourseFile] {
        courseFiles.filter { $0.courseId == courseId }
    }
    
    /// Get files attached to a specific node
    func nodeFiles(for nodeId: UUID) -> [CourseFile] {
        courseFiles.filter { $0.nodeId == nodeId }
    }
    
    /// Get files attached to course root (no node)
    func rootFiles(for courseId: UUID) -> [CourseFile] {
        courseFiles.filter { $0.courseId == courseId && $0.nodeId == nil }
    }
    
    /// Get syllabus for a course (should be only one)
    func syllabus(for courseId: UUID) -> CourseFile? {
        courseFiles.first { $0.courseId == courseId && $0.isSyllabus }
    }
    
    /// Get practice exams for a course
    func practiceExams(for courseId: UUID) -> [CourseFile] {
        courseFiles.filter { $0.courseId == courseId && $0.isPracticeExam }
    }
    
    /// Add a new file
    func addFile(_ file: CourseFile) {
        var newFile = file
        newFile.createdAt = Date()
        newFile.updatedAt = Date()
        
        // Generate content fingerprint if not provided
        if newFile.contentFingerprint.isEmpty {
            newFile.contentFingerprint = generateFingerprint(for: newFile)
        }
        
        // Set initial parse status
        newFile.parseStatus = .queued
        
        // Enforce single syllabus rule
        if newFile.isSyllabus {
            // Unmark any existing syllabus
            for index in courseFiles.indices {
                if courseFiles[index].courseId == newFile.courseId && courseFiles[index].isSyllabus {
                    courseFiles[index].isSyllabus = false
                    courseFiles[index].updatedAt = Date()
                }
            }
        }
        
        courseFiles.append(newFile)
        persist()
        
        // Trigger parsing asynchronously
        Task {
            await FileParsingService.shared.parseFile(newFile)
        }
    }
    
    private func generateFingerprint(for file: CourseFile) -> String {
        // Generate fingerprint from file size + filename + creation date
        let components = [
            file.filename,
            String(file.createdAt.timeIntervalSince1970),
            file.fileType
        ]
        let combined = components.joined(separator: "|")
        return combined.sha256()
    }
    
    /// Update a file
    func updateFile(_ file: CourseFile) {
        guard let index = courseFiles.firstIndex(where: { $0.id == file.id }) else { return }
        
        var updatedFile = file
        updatedFile.updatedAt = Date()
        
        // Enforce single syllabus rule
        if updatedFile.isSyllabus && !courseFiles[index].isSyllabus {
            // Unmark any existing syllabus
            for idx in courseFiles.indices where idx != index {
                if courseFiles[idx].courseId == updatedFile.courseId && courseFiles[idx].isSyllabus {
                    courseFiles[idx].isSyllabus = false
                    courseFiles[idx].updatedAt = Date()
                }
            }
        }
        
        courseFiles[index] = updatedFile
        persist()
    }
    
    /// Delete a file
    func deleteFile(_ id: UUID) {
        courseFiles.removeAll { $0.id == id }
        persist()
    }
    
    /// Attach file to a node
    func attachFile(_ fileId: UUID, to nodeId: UUID?) {
        guard let index = courseFiles.firstIndex(where: { $0.id == fileId }) else { return }
        courseFiles[index].nodeId = nodeId
        courseFiles[index].updatedAt = Date()
        persist()
    }
    
    /// Toggle syllabus designation
    func toggleSyllabus(_ fileId: UUID) {
        guard let index = courseFiles.firstIndex(where: { $0.id == fileId }) else { return }
        let newValue = !courseFiles[index].isSyllabus
        
        if newValue {
            // Unmark any existing syllabus
            let courseId = courseFiles[index].courseId
            for idx in courseFiles.indices where idx != index {
                if courseFiles[idx].courseId == courseId && courseFiles[idx].isSyllabus {
                    courseFiles[idx].isSyllabus = false
                    courseFiles[idx].updatedAt = Date()
                }
            }
            
            // Trigger parsing when marking as syllabus
            Task { @MainActor in
                let parsingStore = SyllabusParsingStore.shared
                let job = parsingStore.createJob(courseId: courseId, fileId: fileId)
                
                // Get file URL from localURL if available
                let fileURL: URL? = if let urlString = courseFiles[index].localURL {
                    URL(fileURLWithPath: urlString)
                } else {
                    nil
                }
                
                parsingStore.startParsing(job: job, fileURL: fileURL)
            }
        }
        
        courseFiles[index].isSyllabus = newValue
        courseFiles[index].updatedAt = Date()
        persist()
    }
    
    /// Toggle practice exam designation
    func togglePracticeExam(_ fileId: UUID) {
        guard let index = courseFiles.firstIndex(where: { $0.id == fileId }) else { return }
        courseFiles[index].isPracticeExam.toggle()
        courseFiles[index].updatedAt = Date()
        persist()
    }
    
    /// Update parse status for a file
    func updateParseStatus(fileId: UUID, status: ParseStatus, error: String?) {
        guard let index = courseFiles.firstIndex(where: { $0.id == fileId }) else { return }
        courseFiles[index].parseStatus = status
        courseFiles[index].parseError = error
        if status == .parsed {
            courseFiles[index].parsedAt = Date()
        }
        courseFiles[index].updatedAt = Date()
        persist()
    }
    
    /// Update file category and trigger parsing if needed
    func updateFileCategory(fileId: UUID, category: FileCategory) {
        guard let index = courseFiles.firstIndex(where: { $0.id == fileId }) else { return }
        let oldCategory = courseFiles[index].category
        courseFiles[index].category = category
        courseFiles[index].updatedAt = Date()
        persist()
        
        // Trigger parsing if changing to a high-signal category
        let highSignalCategories: [FileCategory] = [.syllabus, .test, .practiceTest, .rubric, .classNotes, .assignmentList]
        if highSignalCategories.contains(category) && category != oldCategory {
            Task {
                await FileParsingService.shared.parseFile(courseFiles[index], force: true)
            }
        }
    }
    
    /// Clear all data (for testing)
    func clear() {
        semesters = []
        courses = []
        outlineNodes = []
        courseFiles = []
        currentSemesterId = nil
        currentGPA = 0
        persist()
    }
    
    // MARK: - iCloud Sync
    
    private func setupNetworkMonitoring() {
        pathMonitor = NWPathMonitor()
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isOnline = path.status == .satisfied
            }
        }
        pathMonitor?.start(queue: DispatchQueue.global(qos: .background))
    }
    
    private func setupiCloudMonitoring() {
        iCloudMonitor = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isSyncEnabled else { return }
                self.loadFromiCloud()
            }
        }
    }
    
    private func observeICloudToggle() {
        iCloudToggleObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.isSyncEnabled {
                    self.loadFromiCloud()
                }
            }
        }
    }
    
    private func loadFromiCloudIfEnabled() {
        guard isSyncEnabled else { return }
        guard !AppSettingsModel.shared.suppressICloudRestore else { return }
        loadFromiCloud()
    }
    
    // PHASE 2: Async iCloud loading that merges without multiple publishes
    private func loadFromiCloudIfEnabledAsync() async {
        guard isSyncEnabled else { return }
        guard !AppSettingsModel.shared.suppressICloudRestore else { return }
        guard let url = iCloudURL else { return }
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        
        let localSnapshot = await MainActor.run { [semesters, courses, outlineNodes, courseFiles, currentSemesterId, activeSemesterIds] in
            CoursesPersistedData(
                semesters: semesters,
                courses: courses,
                outlineNodes: outlineNodes,
                courseFiles: courseFiles,
                currentSemesterId: currentSemesterId,
                activeSemesterIds: activeSemesterIds
            )
        }
        
        // Load and decode off-main
        let cloudData = await Task.detached(priority: .utility) { () -> CoursesPersistedData? in
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode(CoursesPersistedData.self, from: data)
                await LOG_PERSISTENCE(.debug, "CoursesiCloud", "Decoded iCloud data off-main")
                return decoded
            } catch {
                await LOG_PERSISTENCE(.error, "CoursesiCloud", "iCloud load failed: \(error.localizedDescription)")
                return nil
            }
        }.value
        
        guard let decoded = cloudData else { return }
        
        let isCloudEmpty = decoded.semesters.isEmpty && decoded.courses.isEmpty
        let hasLocalData = !localSnapshot.semesters.isEmpty || !localSnapshot.courses.isEmpty
        if isCloudEmpty && hasLocalData {
            await MainActor.run {
                hasLoadedFromiCloud = true
            }
            await LOG_PERSISTENCE(.info, "CoursesiCloud", "Skipped empty iCloud merge to preserve local data")
            return
        }
        
        if hasSyncConflict(local: localSnapshot, cloud: decoded) {
            await MainActor.run {
                handleSyncConflict(localData: localSnapshot, cloudData: decoded)
            }
            return
        }
        
        // PHASE 2: Merge on main in ONE update
        await MainActor.run {
            isLoadingFromDisk = true
            self.semesters = decoded.semesters
            self.courses = decoded.courses
            self.outlineNodes = decoded.outlineNodes
            self.courseFiles = decoded.courseFiles
            self.currentSemesterId = decoded.currentSemesterId
            if let activeSemesterIdsArray = decoded.activeSemesterIds {
                self.activeSemesterIds = Set(activeSemesterIdsArray)
            } else if let currentId = decoded.currentSemesterId {
                self.activeSemesterIds = [currentId]
            }
            isLoadingFromDisk = false
            hasLoadedFromiCloud = true
            LOG_PERSISTENCE(.info, "CoursesiCloud", "iCloud data merged", metadata: ["semesters": "\(semesters.count)"])
        }
    }
    
    private func saveToiCloud() {
        guard isSyncEnabled else { return }
        guard let url = iCloudURL else { return }
        if !hasLoadedFromiCloud && semesters.isEmpty && courses.isEmpty {
            LOG_PERSISTENCE(.info, "CoursesiCloud", "Skipped iCloud sync with empty local data before initial load")
            return
        }

        let snapshot = CoursesPersistedData(
            semesters: semesters,
            courses: courses,
            outlineNodes: outlineNodes,
            courseFiles: courseFiles,
            currentSemesterId: currentSemesterId,
            activeSemesterIds: activeSemesterIds
        )

        DispatchQueue.global(qos: .utility).async {
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: url, options: .atomic)
                LOG_PERSISTENCE(.info, "CoursesiCloud", "Synced courses to iCloud", metadata: ["semesters": "\(snapshot.semesters.count)", "courses": "\(snapshot.courses.count)"])
            } catch {
                LOG_PERSISTENCE(.error, "CoursesiCloud", "iCloud sync failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadFromiCloud() {
        guard let url = iCloudURL else { return }
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            let localSnapshot = CoursesPersistedData(
                semesters: semesters,
                courses: courses,
                outlineNodes: outlineNodes,
                courseFiles: courseFiles,
                currentSemesterId: currentSemesterId,
                activeSemesterIds: activeSemesterIds
            )
            
            isLoadingFromDisk = true
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(CoursesPersistedData.self, from: data)
            
            let isCloudEmpty = decoded.semesters.isEmpty && decoded.courses.isEmpty
            let hasLocalData = !localSnapshot.semesters.isEmpty || !localSnapshot.courses.isEmpty
            if isCloudEmpty && hasLocalData {
                isLoadingFromDisk = false
                hasLoadedFromiCloud = true
                LOG_PERSISTENCE(.info, "CoursesiCloud", "Skipped empty iCloud merge to preserve local data")
                return
            }
            
            if hasSyncConflict(local: localSnapshot, cloud: decoded) {
                isLoadingFromDisk = false
                handleSyncConflict(localData: localSnapshot, cloudData: decoded)
                return
            }
            
            self.semesters = decoded.semesters
            self.courses = decoded.courses
            self.outlineNodes = decoded.outlineNodes
            self.courseFiles = decoded.courseFiles
            self.currentSemesterId = decoded.currentSemesterId
            if let activeSemesterIdsArray = decoded.activeSemesterIds {
                self.activeSemesterIds = Set(activeSemesterIdsArray)
            } else if let currentId = decoded.currentSemesterId {
                self.activeSemesterIds = [currentId]
            }
            
            LOG_PERSISTENCE(.info, "CoursesiCloud", "Loaded courses from iCloud", metadata: ["semesters": "\(semesters.count)", "courses": "\(courses.count)"])
            isLoadingFromDisk = false
            hasLoadedFromiCloud = true
        } catch {
            isLoadingFromDisk = false
            LOG_PERSISTENCE(.error, "CoursesiCloud", "Failed to load from iCloud: \(error.localizedDescription)")
        }
    }
}

// MARK: - iCloud Conflict Resolution

extension CoursesStore {
    func resolveSyncConflict(useCloud: Bool) {
        guard let cloudData = pendingCloudConflict else { return }
        pendingCloudConflict = nil
        
        if useCloud {
            applySnapshot(cloudData)
            LOG_PERSISTENCE(.info, "CoursesiCloud", "Resolved sync conflict using iCloud data")
        } else {
            hasLoadedFromiCloud = true
            saveToiCloud()
            LOG_PERSISTENCE(.info, "CoursesiCloud", "Resolved sync conflict keeping local data")
        }
    }
    
    private func applySnapshot(_ snapshot: CoursesPersistedData) {
        isLoadingFromDisk = true
        semesters = snapshot.semesters
        courses = snapshot.courses
        outlineNodes = snapshot.outlineNodes
        courseFiles = snapshot.courseFiles
        currentSemesterId = snapshot.currentSemesterId
        if let activeSemesterIdsArray = snapshot.activeSemesterIds {
            activeSemesterIds = Set(activeSemesterIdsArray)
        } else if let currentId = snapshot.currentSemesterId {
            activeSemesterIds = [currentId]
        } else {
            activeSemesterIds = []
        }
        isLoadingFromDisk = false
        hasLoadedFromiCloud = true
        persist()
    }
    
    private func handleSyncConflict(localData: CoursesPersistedData, cloudData: CoursesPersistedData) {
        pendingCloudConflict = cloudData
        hasLoadedFromiCloud = true
        NotificationCenter.default.post(
            name: .coursesSyncConflict,
            object: nil,
            userInfo: [
                "localSemesters": localData.semesters.count,
                "localCourses": localData.courses.count,
                "cloudSemesters": cloudData.semesters.count,
                "cloudCourses": cloudData.courses.count
            ]
        )
        LOG_PERSISTENCE(.warn, "CoursesiCloud", "Sync conflict detected", metadata: [
            "localSemesters": "\(localData.semesters.count)",
            "localCourses": "\(localData.courses.count)",
            "cloudSemesters": "\(cloudData.semesters.count)",
            "cloudCourses": "\(cloudData.courses.count)"
        ])
    }
    
    private func hasSyncConflict(local: CoursesPersistedData, cloud: CoursesPersistedData) -> Bool {
        let localHasData = !local.semesters.isEmpty || !local.courses.isEmpty
        let cloudHasData = !cloud.semesters.isEmpty || !cloud.courses.isEmpty
        guard localHasData && cloudHasData else { return false }
        
        let localSemesterIds = Set(local.semesters.map { $0.id })
        let cloudSemesterIds = Set(cloud.semesters.map { $0.id })
        if localSemesterIds != cloudSemesterIds {
            return true
        }
        
        let localCourseIds = Set(local.courses.map { $0.id })
        let cloudCourseIds = Set(cloud.courses.map { $0.id })
        return localCourseIds != cloudCourseIds
    }
}

// Combine publisher replaces brittle NotificationCenter bridges
extension CoursesStore {
    // Emits courseId when a course is removed
    static var courseDeletedPublisher: AnyPublisher<UUID, Never> {
        guard let s = CoursesStore.shared else { return Empty<UUID, Never>().eraseToAnyPublisher() }
        return s.courseDeleted.eraseToAnyPublisher()
    }
}
