import Foundation
import Combine

@MainActor
final class StorageAggregateStore: ObservableObject {
    static let shared = StorageAggregateStore()

    @Published private(set) var buckets: [String: [StorageEntityType: Int]] = [:]
    @Published private(set) var aggregates = RetentionAggregates()

    private let storageURL: URL

    private init(storageURL: URL? = nil) {
        let fm = FileManager.default
        if let storageURL {
            self.storageURL = storageURL
        } else {
            let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let folder = dir.appendingPathComponent("RootsStorage", isDirectory: true)
            try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
            self.storageURL = folder.appendingPathComponent("aggregate_storage.json")
        }
        load()
    }

    func recordDeletion(type: StorageEntityType, date: Date) {
        let key = monthKey(for: date)
        var counts = buckets[key, default: [:]]
        counts[type, default: 0] += 1
        buckets[key] = counts
        persist()
    }

    func recordStudyTime(_ seconds: TimeInterval, key: AggregateKey) {
        aggregates.studyTime[key, default: 0] += seconds
        persist()
    }

    func recordAssignmentCompletion(isOnTime: Bool, key: AggregateKey) {
        var metrics = aggregates.assignmentMetrics[key, default: AssignmentAggregateMetrics()]
        metrics.completedCount += 1
        if isOnTime { metrics.onTimeCount += 1 }
        aggregates.assignmentMetrics[key] = metrics
        persist()
    }

    func recordGrade(_ percentage: Double, key: AggregateKey) {
        var metrics = aggregates.gradeMetrics[key, default: GradeAggregateMetrics()]
        metrics.percentages.append(percentage)
        aggregates.gradeMetrics[key] = metrics
        persist()
    }

    func recordCalendarWorkload(events: Int, durationSeconds: TimeInterval, key: AggregateKey) {
        var metrics = aggregates.calendarMetrics[key, default: CalendarAggregateMetrics()]
        metrics.eventCount += events
        metrics.totalDurationSeconds += durationSeconds
        aggregates.calendarMetrics[key] = metrics
        persist()
    }

    private func monthKey(for date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month], from: date)
        let year = comps.year ?? 0
        let month = comps.month ?? 0
        return String(format: "%04d-%02d", year, month)
    }

    private func persist() {
        do {
            let payload = StorageAggregatePayload(buckets: buckets, aggregates: aggregates)
            let data = try JSONEncoder().encode(payload)
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            LOG_DATA(.error, "StorageAggregate", "Failed to persist aggregate storage: \(error.localizedDescription)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let payload = try JSONDecoder().decode(StorageAggregatePayload.self, from: data)
            buckets = payload.buckets
            aggregates = payload.aggregates
        } catch {
            LOG_DATA(.error, "StorageAggregate", "Failed to load aggregate storage: \(error.localizedDescription)")
        }
    }
}

private struct StorageAggregatePayload: Codable {
    var buckets: [String: [StorageEntityType: Int]]
    var aggregates: RetentionAggregates
}
