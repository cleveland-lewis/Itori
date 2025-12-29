import Foundation
import Combine

struct StoredScheduledSession: Identifiable, Codable, Hashable {
    let id: UUID
    let assignmentId: UUID?
    let sessionIndex: Int?
    let sessionCount: Int?
    let title: String
    let dueDate: Date
    let estimatedMinutes: Int
    let isLockedToDueDate: Bool
    let category: AssignmentCategory?
    let start: Date
    let end: Date
    let type: ScheduleBlockType
    let isLocked: Bool
    let isUserEdited: Bool
    let userEditedAt: Date?
    let aiInputHash: String?
    let aiComputedAt: Date?
    let aiConfidence: Double?
    let aiProvenance: String?

    init(id: UUID,
         assignmentId: UUID?,
         sessionIndex: Int?,
         sessionCount: Int?,
         title: String,
         dueDate: Date,
         estimatedMinutes: Int,
         isLockedToDueDate: Bool,
         category: AssignmentCategory?,
         start: Date,
         end: Date,
         type: ScheduleBlockType = .task,
         isLocked: Bool = false,
         isUserEdited: Bool = false,
         userEditedAt: Date? = nil,
         aiInputHash: String? = nil,
         aiComputedAt: Date? = nil,
         aiConfidence: Double? = nil,
         aiProvenance: String? = nil) {
        self.id = id
        self.assignmentId = assignmentId
        self.sessionIndex = sessionIndex
        self.sessionCount = sessionCount
        self.title = title
        self.dueDate = dueDate
        self.estimatedMinutes = estimatedMinutes
        self.isLockedToDueDate = isLockedToDueDate
        self.category = category
        self.start = start
        self.end = end
        self.type = type
        self.isLocked = isLocked
        self.isUserEdited = isUserEdited
        self.userEditedAt = userEditedAt
        self.aiInputHash = aiInputHash
        self.aiComputedAt = aiComputedAt
        self.aiConfidence = aiConfidence
        self.aiProvenance = aiProvenance
    }

    private enum CodingKeys: String, CodingKey {
        case id, assignmentId, sessionIndex, sessionCount, title, dueDate, estimatedMinutes
        case isLockedToDueDate, category, start, end, type, isLocked, isUserEdited, userEditedAt
        case aiInputHash, aiComputedAt, aiConfidence, aiProvenance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        assignmentId = try container.decodeIfPresent(UUID.self, forKey: .assignmentId)
        sessionIndex = try container.decodeIfPresent(Int.self, forKey: .sessionIndex)
        sessionCount = try container.decodeIfPresent(Int.self, forKey: .sessionCount)
        title = try container.decode(String.self, forKey: .title)
        dueDate = try container.decode(Date.self, forKey: .dueDate)
        estimatedMinutes = try container.decode(Int.self, forKey: .estimatedMinutes)
        isLockedToDueDate = try container.decode(Bool.self, forKey: .isLockedToDueDate)
        category = try container.decodeIfPresent(AssignmentCategory.self, forKey: .category)
        start = try container.decode(Date.self, forKey: .start)
        end = try container.decode(Date.self, forKey: .end)
        type = try container.decodeIfPresent(ScheduleBlockType.self, forKey: .type) ?? .task
        isLocked = try container.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        isUserEdited = try container.decodeIfPresent(Bool.self, forKey: .isUserEdited) ?? false
        userEditedAt = try container.decodeIfPresent(Date.self, forKey: .userEditedAt)
        aiInputHash = try container.decodeIfPresent(String.self, forKey: .aiInputHash)
        aiComputedAt = try container.decodeIfPresent(Date.self, forKey: .aiComputedAt)
        aiConfidence = try container.decodeIfPresent(Double.self, forKey: .aiConfidence)
        aiProvenance = try container.decodeIfPresent(String.self, forKey: .aiProvenance)
    }
    
    // MARK: - UI Helpers
    
    /// System icon name for consistent rendering across platforms
    var iconName: String {
        switch type {
        case .breakTime:
            // Determine if short or long break based on duration
            return estimatedMinutes >= 15 ? "moon.fill" : "cup.and.saucer.fill"
        case .study, .task:
            return isUserEdited ? "pencil.and.outline" : "calendar.badge.clock"
        case .event:
            return "calendar"
        }
    }
    
    /// Whether this session is a break
    var isBreak: Bool {
        type == .breakTime
    }
}

struct StoredOverflowSession: Identifiable, Codable, Hashable {
    let id: UUID
    let assignmentId: UUID?
    let sessionIndex: Int?
    let sessionCount: Int?
    let title: String
    let dueDate: Date
    let estimatedMinutes: Int
    let isLockedToDueDate: Bool
    let category: AssignmentCategory?
    let aiInputHash: String?
    let aiComputedAt: Date?
    let aiConfidence: Double?
    let aiProvenance: String?
}

enum ScheduleBlockType: String, Codable, CaseIterable {
    case task
    case event
    case study
    case breakTime
}

@MainActor
final class PlannerStore: ObservableObject {
    static let shared = PlannerStore()

    @Published var isLoading: Bool = true
    @Published private(set) var scheduled: [StoredScheduledSession] = []
    @Published private(set) var overflow: [StoredOverflowSession] = []

    private let storageURL: URL

    private init() {
        let fm = FileManager.default
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = dir.appendingPathComponent("RootsPlanner", isDirectory: true)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        self.storageURL = folder.appendingPathComponent("planner_sessions.json")
        load()
        isLoading = false
    }

    func persist(scheduled: [ScheduledSession], overflow: [PlannerSession], metadata: AIScheduleMetadata? = nil) {
        let preserved = Dictionary(grouping: self.scheduled.filter { $0.isUserEdited }, by: {
            PlannerSessionKey(assignmentId: $0.assignmentId, title: $0.title)
        })
        let existingByIndex = Dictionary(grouping: self.scheduled, by: {
            PlannerSessionIndexKey(assignmentId: $0.assignmentId, sessionIndex: $0.sessionIndex)
        })
        self.scheduled = scheduled.map {
            var mapped = StoredScheduledSession(
                id: $0.id,
                assignmentId: $0.session.assignmentId,
                sessionIndex: $0.session.sessionIndex,
                sessionCount: $0.session.sessionCount,
                title: $0.session.title,
                dueDate: $0.session.dueDate,
                estimatedMinutes: $0.session.estimatedMinutes,
                isLockedToDueDate: $0.session.isLockedToDueDate,
                category: $0.session.category,
                start: $0.start,
                end: $0.end,
                type: .task,
                isLocked: $0.session.isLockedToDueDate,
                isUserEdited: false,
                userEditedAt: nil,
                aiInputHash: metadata?.inputHash,
                aiComputedAt: metadata?.computedAt,
                aiConfidence: metadata?.confidence,
                aiProvenance: metadata?.provenance
            )
            if let match = preserved[PlannerSessionKey(assignmentId: mapped.assignmentId, title: mapped.title)]?.first {
                mapped = StoredScheduledSession(
                    id: mapped.id,
                    assignmentId: mapped.assignmentId,
                    sessionIndex: mapped.sessionIndex,
                    sessionCount: mapped.sessionCount,
                    title: mapped.title,
                    dueDate: mapped.dueDate,
                    estimatedMinutes: mapped.estimatedMinutes,
                    isLockedToDueDate: mapped.isLockedToDueDate,
                    category: mapped.category,
                    start: match.start,
                    end: match.end,
                    type: match.type,
                    isLocked: match.isLocked,
                    isUserEdited: true,
                    userEditedAt: match.userEditedAt,
                    aiInputHash: match.aiInputHash,
                    aiComputedAt: match.aiComputedAt,
                    aiConfidence: match.aiConfidence,
                    aiProvenance: match.aiProvenance
                )
                return mapped
            }

            if let meta = metadata,
               let existing = existingByIndex[PlannerSessionIndexKey(assignmentId: mapped.assignmentId, sessionIndex: mapped.sessionIndex)]?.first {
                if let editAt = existing.userEditedAt, editAt >= meta.computedAt {
                    return existing
                }
                if let existingComputed = existing.aiComputedAt, existingComputed > meta.computedAt {
                    return existing
                }
            }
            return mapped
        }
        self.overflow = overflow.map {
            StoredOverflowSession(
                id: $0.id,
                assignmentId: $0.assignmentId,
                sessionIndex: $0.sessionIndex,
                sessionCount: $0.sessionCount,
                title: $0.title,
                dueDate: $0.dueDate,
                estimatedMinutes: $0.estimatedMinutes,
                isLockedToDueDate: $0.isLockedToDueDate,
                category: $0.category,
                aiInputHash: metadata?.inputHash,
                aiComputedAt: metadata?.computedAt,
                aiConfidence: metadata?.confidence,
                aiProvenance: metadata?.provenance
            )
        }
        save()
    }

    private struct PlannerSessionKey: Hashable {
        let assignmentId: UUID?
        let title: String
    }

    private struct PlannerSessionIndexKey: Hashable {
        let assignmentId: UUID?
        let sessionIndex: Int?
    }

    func updateScheduledSession(_ updated: StoredScheduledSession) {
        guard let idx = scheduled.firstIndex(where: { $0.id == updated.id }) else { return }
        let editTime = updated.isUserEdited ? (updated.userEditedAt ?? Date()) : updated.userEditedAt
        let merged = StoredScheduledSession(
            id: updated.id,
            assignmentId: updated.assignmentId,
            sessionIndex: updated.sessionIndex,
            sessionCount: updated.sessionCount,
            title: updated.title,
            dueDate: updated.dueDate,
            estimatedMinutes: updated.estimatedMinutes,
            isLockedToDueDate: updated.isLockedToDueDate,
            category: updated.category,
            start: updated.start,
            end: updated.end,
            type: updated.type,
            isLocked: updated.isLocked,
            isUserEdited: updated.isUserEdited,
            userEditedAt: editTime,
            aiInputHash: updated.aiInputHash,
            aiComputedAt: updated.aiComputedAt,
            aiConfidence: updated.aiConfidence,
            aiProvenance: updated.aiProvenance
        )
        scheduled[idx] = merged
        save()
    }

    func reset() {
        scheduled.removeAll()
        overflow.removeAll()
        save()
    }

    private func save() {
        do {
            let payload = Persisted(scheduled: scheduled, overflow: overflow)
            let data = try JSONEncoder().encode(payload)
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            print("Failed to save planner sessions: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let payload = try JSONDecoder().decode(Persisted.self, from: data)
            scheduled = payload.scheduled
            overflow = payload.overflow
        } catch {
            print("Failed to load planner sessions: \(error)")
        }
    }

    private struct Persisted: Codable {
        var scheduled: [StoredScheduledSession]
        var overflow: [StoredOverflowSession]
    }
}

struct AIScheduleMetadata: Hashable {
    let inputHash: String
    let computedAt: Date
    let confidence: Double
    let provenance: String
}
