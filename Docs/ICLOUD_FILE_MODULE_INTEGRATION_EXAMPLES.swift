import Foundation
import SwiftUI
import Combine

// MARK: - Example: CoursesStore Integration

/// Updated CoursesStore using new persistence layer
class CoursesStoreWithPersistence: ObservableObject {
    @Published var modules: [CourseOutlineNode] = []
    @Published var files: [CourseFile] = []
    @Published var syncStatus: String = "Idle"
    @Published var isLoading: Bool = false
    
    private let moduleRepository = CourseModuleRepository()
    private let fileSyncManager = CourseFileCloudSyncManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        observeSyncStatus()
    }
    
    // MARK: - Module Operations
    
    func loadModules(for courseId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let loadedModules = try await moduleRepository.fetchModules(for: courseId)
            await MainActor.run {
                self.modules = loadedModules
            }
        } catch {
            print("❌ Failed to load modules: \(error)")
        }
    }
    
    func createModule(
        courseId: UUID,
        title: String,
        type: CourseOutlineNodeType = .module
    ) async throws {
        let module = try await moduleRepository.createModule(
            courseId: courseId,
            type: type,
            title: title,
            sortIndex: modules.count
        )
        
        await MainActor.run {
            modules.append(module)
        }
    }
    
    func updateModule(id: UUID, title: String) async throws {
        try await moduleRepository.updateModule(
            id: id,
            title: title
        )
        
        // Reload to get updated data
        if let courseId = modules.first(where: { $0.id == id })?.courseId {
            await loadModules(for: courseId)
        }
    }
    
    func deleteModule(id: UUID) async throws {
        try await moduleRepository.deleteModule(id: id)
        
        await MainActor.run {
            modules.removeAll { $0.id == id }
        }
    }
    
    // MARK: - File Operations
    
    func loadFiles(courseId: UUID, moduleId: UUID? = nil) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let loadedFiles = try await moduleRepository.fetchFiles(
                courseId: courseId,
                nodeId: moduleId
            )
            await MainActor.run {
                self.files = loadedFiles
            }
        } catch {
            print("❌ Failed to load files: \(error)")
        }
    }
    
    func addFile(
        courseId: UUID,
        moduleId: UUID?,
        url: URL,
        isSyllabus: Bool = false,
        isPracticeExam: Bool = false
    ) async throws {
        // Add to database
        let file = try await moduleRepository.addFile(
            courseId: courseId,
            nodeId: moduleId,
            fileName: url.lastPathComponent,
            fileType: url.pathExtension,
            localURL: url.path,
            isSyllabus: isSyllabus,
            isPracticeExam: isPracticeExam
        )
        
        // Upload to iCloud
        _ = try await fileSyncManager.uploadFile(
            fileId: file.id,
            localURL: url,
            courseId: courseId,
            nodeId: moduleId
        )
        
        await MainActor.run {
            files.append(file)
        }
    }
    
    func openFile(fileId: UUID, iCloudPath: String?) async throws -> URL {
        return try await fileSyncManager.getFileURL(
            fileId: fileId,
            iCloudPath: iCloudPath
        )
    }
    
    func deleteFile(id: UUID, iCloudPath: String?) async throws {
        try await fileSyncManager.deleteFile(
            fileId: id,
            iCloudPath: iCloudPath
        )
        
        await MainActor.run {
            files.removeAll { $0.id == id }
        }
    }
    
    // MARK: - Sync Monitoring
    
    private func observeSyncStatus() {
        fileSyncManager.$syncStatus
            .sink { [weak self] status in
                Task { @MainActor in
                    switch status {
                    case .idle:
                        self?.syncStatus = "Synced"
                    case .syncing(let progress):
                        self?.syncStatus = "Syncing \(Int(progress * 100))%"
                    case .error(let message):
                        self?.syncStatus = "Error: \(message)"
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Example: PlannerService Integration

/// Updated PlannerService using analysis persistence
class PlannerServiceWithPersistence {
    private let analysisRepository = PlannerAnalysisRepository()
    
    func generateWeeklyPlan(
        assignments: [Assignment],
        startDate: Date,
        endDate: Date
    ) async throws {
        // Perform analysis (existing logic)
        let totalHours = assignments.reduce(0) { $0 + Double($1.estimatedMinutes) / 60.0 }
        let avgDifficulty = assignments.reduce(0.0) { $0 + $1.difficulty } / Double(assignments.count)
        
        let recommendations = generateRecommendations(
            totalHours: totalHours,
            difficulty: avgDifficulty
        )
        
        // Save to database
        _ = try await analysisRepository.saveAnalysis(
            type: "weekly_plan",
            startDate: startDate,
            endDate: endDate,
            analysisData: [
                "assignments": assignments.map { $0.id.uuidString },
                "total_hours": totalHours,
                "average_difficulty": avgDifficulty
            ],
            resultData: [
                "recommendations": recommendations,
                "daily_distribution": calculateDailyDistribution(
                    totalHours: totalHours,
                    days: 7
                )
            ]
        )
    }
    
    func loadPreviousAnalysis(for week: Date) async throws -> PlannerAnalysisResult? {
        return try await analysisRepository.fetchLatestAnalysis(type: "weekly_plan")
    }
    
    func cleanupOldAnalyses() async throws {
        let threeMonthsAgo = Date().addingTimeInterval(-90 * 24 * 60 * 60)
        let deletedCount = try await analysisRepository.deleteOldAnalyses(olderThan: threeMonthsAgo)
        print("🧹 Cleaned up \(deletedCount) old analyses")
    }
    
    // MARK: - Helpers
    
    private func generateRecommendations(totalHours: Double, difficulty: Double) -> [String] {
        var recommendations: [String] = []
        
        if totalHours > 40 {
            recommendations.append("Consider reducing workload or spreading tasks over more days")
        }
        
        if difficulty > 0.7 {
            recommendations.append("Start early on difficult assignments")
            recommendations.append("Break work into smaller, manageable chunks")
        }
        
        if totalHours < 10 {
            recommendations.append("Good week to review previous material")
        }
        
        return recommendations
    }
    
    private func calculateDailyDistribution(totalHours: Double, days: Int) -> [String: Double] {
        let hoursPerDay = totalHours / Double(days)
        var distribution: [String: Double] = [:]
        
        let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        for day in weekdays {
            distribution[day] = hoursPerDay
        }
        
        return distribution
    }
}

// MARK: - Example: SwiftUI View Integration

struct ModulesListView: View {
    @StateObject private var store = CoursesStoreWithPersistence()
    let courseId: UUID
    
    @State private var showingAddModule = false
    @State private var newModuleTitle = ""
    
    var body: some View {
        VStack {
            // Sync status
            HStack {
                Image(systemName: syncStatusIcon)
                    .foregroundColor(syncStatusColor)
                Text(store.syncStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            
            // Modules list
            List {
                ForEach(store.modules) { module in
                    ModuleRow(module: module)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    try? await store.deleteModule(id: module.id)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .refreshable {
                await store.loadModules(for: courseId)
            }
        }
        .navigationTitle("Modules")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddModule = true
                } label: {
                    Label("Add Module", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddModule) {
            AddModuleSheet(
                newModuleTitle: $newModuleTitle,
                onSave: {
                    Task {
                        try? await store.createModule(
                            courseId: courseId,
                            title: newModuleTitle
                        )
                        showingAddModule = false
                        newModuleTitle = ""
                    }
                }
            )
        }
        .task {
            await store.loadModules(for: courseId)
        }
    }
    
    private var syncStatusIcon: String {
        switch store.syncStatus {
        case "Synced":
            return "checkmark.icloud"
        case let status where status.starts(with: "Syncing"):
            return "icloud.and.arrow.up"
        case let status where status.starts(with: "Error"):
            return "exclamationmark.icloud"
        default:
            return "icloud"
        }
    }
    
    private var syncStatusColor: Color {
        switch store.syncStatus {
        case "Synced":
            return .green
        case let status where status.starts(with: "Syncing"):
            return .blue
        case let status where status.starts(with: "Error"):
            return .red
        default:
            return .gray
        }
    }
}

struct ModuleRow: View {
    let module: CourseOutlineNode
    
    var body: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading) {
                Text(module.title)
                    .font(.headline)
                
                Text(module.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(module.createdAt, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AddModuleSheet: View {
    @Binding var newModuleTitle: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Module Title", text: $newModuleTitle)
            }
            .navigationTitle("New Module")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(newModuleTitle.isEmpty)
                }
            }
        }
    }
}

// MARK: - Example: File Parsing Integration

class FileParsingServiceWithPersistence {
    private let moduleRepository = CourseModuleRepository()
    
    func parseFile(_ file: CourseFile) async throws {
        // Update status to parsing
        try await moduleRepository.updateFileParse(
            id: file.id,
            parseStatus: .parsing
        )
        
        do {
            // Perform parsing (existing logic)
            let extractedText = try await extractText(from: file)
            let metadata = try await extractMetadata(from: file)
            
            // Save parse result
            try await moduleRepository.saveParseResult(
                fileId: file.id,
                parseType: "text_extraction",
                success: true,
                extractedText: extractedText,
                contentJSON: metadata,
                errorMessage: nil
            )
            
            // Update status to parsed
            try await moduleRepository.updateFileParse(
                id: file.id,
                parseStatus: .parsed
            )
            
            print("✅ Successfully parsed: \(file.filename)")
        } catch {
            // Update with error
            try await moduleRepository.updateFileParse(
                id: file.id,
                parseStatus: .failed,
                parseError: error.localizedDescription
            )
            
            print("❌ Failed to parse: \(file.filename) - \(error)")
            throw error
        }
    }
    
    private func extractText(from file: CourseFile) async throws -> String {
        // Existing text extraction logic
        return "Sample extracted text"
    }
    
    private func extractMetadata(from file: CourseFile) async throws -> String {
        // Existing metadata extraction logic
        let metadata: [String: Any] = [
            "pages": 5,
            "wordCount": 1000,
            "hasImages": true
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: metadata)
        return String(data: jsonData, encoding: .utf8) ?? "{}"
    }
}

// MARK: - Example: Migration Usage

class MigrationCoordinator {
    private let migrationManager = PersistenceMigrationManager()
    
    func migrateAllData(
        existingModules: [CourseOutlineNode],
        existingFiles: [CourseFile],
        courseId: UUID
    ) async throws {
        print("🚀 Starting migration...")
        
        // Migrate modules
        try await migrationManager.migrateModules(
            existingModules,
            courseId: courseId
        )
        print("✅ Modules migrated")
        
        // Migrate files
        try await migrationManager.migrateFiles(
            existingFiles,
            courseId: courseId
        )
        print("✅ Files migrated")
        
        print("🎉 Migration complete!")
    }
}
