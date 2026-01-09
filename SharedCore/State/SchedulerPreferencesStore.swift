import Foundation

final class SchedulerPreferencesStore {
    static let shared = SchedulerPreferencesStore()
    private init() { load() }

    private let fileURL: URL? = {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        else { return nil }
        let appDir = dir.appendingPathComponent("Itori", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("scheduler_prefs.json")
    }()

    var preferences: SchedulerPreferences = .default()

    func updateEnergyProfile(_ energy: [Int: Double]) {
        preferences.learnedEnergyProfile = energy
        save()
    }

    func energyProfileForPlanning(settings: AppSettingsModel = .shared) -> [Int: Double] {
        let base = preferences.learnedEnergyProfile
        guard settings.showEnergyPanel else {
            return mediumEnergyProfile()
        }
        var adjusted = base
        if settings.energySelectionConfirmed {
            let delta = energyDelta(for: settings.defaultEnergyLevel)
            if delta != 0 {
                adjusted = adjusted.mapValues { min(1.0, max(0.0, $0 + delta)) }
            }
        }
        return applySessionPreferences(to: adjusted, settings: settings)
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

    func resetAll() {
        preferences = SchedulerPreferences.default()
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        save()
    }

    private func energyDelta(for level: String) -> Double {
        switch level.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "high":
            0.35
        case "low":
            -0.35
        default:
            0.0
        }
    }

    private func applySessionPreferences(to profile: [Int: Double], settings: AppSettingsModel) -> [Int: Double] {
        var adjusted = profile
        if settings.preferMorningSessions {
            for hour in 7 ... 11 {
                adjusted[hour] = min(1.0, (adjusted[hour] ?? 0.5) + 0.15)
            }
        }
        if settings.preferEveningSessions {
            for hour in 18 ... 22 {
                adjusted[hour] = min(1.0, (adjusted[hour] ?? 0.5) + 0.15)
            }
        }
        return adjusted
    }

    private func mediumEnergyProfile() -> [Int: Double] {
        var profile: [Int: Double] = [:]
        for hour in 0 ..< 24 {
            profile[hour] = 0.5
        }
        return profile
    }
}
