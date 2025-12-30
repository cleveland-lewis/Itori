import Foundation

final class SchedulerPreferencesStore {
    static let shared = SchedulerPreferencesStore()
    private init() { load() }

    private let fileURL: URL? = {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let appDir = dir.appendingPathComponent("Roots", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("scheduler_prefs.json")
    }()

    var preferences: SchedulerPreferences = SchedulerPreferences.default()

    func updateEnergyProfile(_ energy: [Int: Double]) {
        preferences.learnedEnergyProfile = energy
        save()
    }

    func energyProfileForPlanning(settings: AppSettingsModel = .shared) -> [Int: Double] {
        let base = preferences.learnedEnergyProfile
        guard settings.energySelectionConfirmed else { return base }
        let delta = energyDelta(for: settings.defaultEnergyLevel)
        guard delta != 0 else { return base }
        return base.mapValues { min(1.0, max(0.0, $0 + delta)) }
    }

    func load() {
        guard let url = fileURL, FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            preferences = try decoder.decode(SchedulerPreferences.self, from: data)
        } catch {
            DebugLogger.log("Failed to load prefs: \(error)")
            preferences = SchedulerPreferences.default()
        }
    }

    func save() {
        guard let url = fileURL else { return }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(preferences)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch {
            DebugLogger.log("Failed to save prefs: \(error)")
        }
    }

    private func energyDelta(for level: String) -> Double {
        switch level.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "high":
            return 0.2
        case "low":
            return -0.2
        default:
            return 0.0
        }
    }
}
