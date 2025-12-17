import Foundation
import Combine

@MainActor
final class ActivityManager: ObservableObject {
    // MARK: - Published State
    
    @Published private(set) var activities: [LocalTimerActivity] = []
    @Published var selectedActivityID: UUID?
    @Published var activityNotes: [UUID: String] = [:]
    
    // MARK: - Configuration
    
    private let fileURL: URL
    private let notesKeyPrefix = "timer.activity.notes."
    
    // MARK: - Initialization
    
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent("TimerActivities.json")
    }
    
    // MARK: - Public API
    
    func load() async {
        if selectedActivityID == nil {
            selectedActivityID = activities.first?.id
        }
        
        for activity in activities {
            loadNotes(for: activity.id)
        }
    }
    
    func add(_ activity: LocalTimerActivity) {
        activities.append(activity)
        selectedActivityID = activity.id
        persist()
    }
    
    func update(_ activity: LocalTimerActivity) {
        guard let idx = activities.firstIndex(where: { $0.id == activity.id }) else { return }
        activities[idx] = activity
        persist()
    }
    
    func delete(_ activity: LocalTimerActivity) {
        activities.removeAll { $0.id == activity.id }
        
        if selectedActivityID == activity.id {
            selectedActivityID = activities.first?.id
        }
        
        persist()
    }
    
    func togglePin(_ activity: LocalTimerActivity) {
        guard let idx = activities.firstIndex(of: activity) else { return }
        activities[idx].isPinned.toggle()
        persist()
    }
    
    func resetTracking(_ activity: LocalTimerActivity) {
        guard let idx = activities.firstIndex(of: activity) else { return }
        activities[idx].todayTrackedSeconds = 0
        activities[idx].totalTrackedSeconds = 0
        persist()
    }
    
    func updateTrackedTime(for activityID: UUID, workSeconds: TimeInterval) {
        guard let idx = activities.firstIndex(where: { $0.id == activityID }) else { return }
        activities[idx].todayTrackedSeconds += workSeconds
        activities[idx].totalTrackedSeconds += workSeconds
        persist()
    }
    
    func saveNotes(_ notes: String, for activityID: UUID) {
        activityNotes[activityID] = notes
        let key = notesKeyPrefix + activityID.uuidString
        UserDefaults.standard.set(notes, forKey: key)
    }
    
    func loadNotes(for activityID: UUID) {
        let key = notesKeyPrefix + activityID.uuidString
        if let stored = UserDefaults.standard.string(forKey: key) {
            activityNotes[activityID] = stored
        }
    }
    
    func currentActivity() -> LocalTimerActivity? {
        activities.first(where: { $0.id == selectedActivityID }) ?? activities.first
    }
    
    func pinnedActivities() -> [LocalTimerActivity] {
        activities.filter { $0.isPinned }
    }
    
    func unpinnedActivities() -> [LocalTimerActivity] {
        activities.filter { !$0.isPinned }
    }
    
    func filteredActivities(searchText: String, collection: String) -> [LocalTimerActivity] {
        var filtered = activities
        
        if !searchText.isEmpty {
            filtered = filtered.filter { activity in
                activity.name.localizedCaseInsensitiveContains(searchText) ||
                activity.category.localizedCaseInsensitiveContains(searchText) ||
                (activity.courseCode?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        if collection != "All" {
            filtered = filtered.filter { $0.category == collection }
        }
        
        return filtered
    }
    
    func collections() -> [String] {
        let allCategories = Set(activities.map { $0.category })
        return ["All"] + allCategories.sorted()
    }
    
    // MARK: - Private Persistence
    
    private func persist() {
        // Activities persistence is managed externally
    }
}
