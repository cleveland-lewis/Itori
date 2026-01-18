import CryptoKit
import Foundation

struct PlannerCalendarBlock: Equatable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let notes: String
    let dayKey: String
}

struct PlannerCalendarMetadata: Equatable {
    let blockId: String
    let source: String
    let dayKey: String
}

struct PlannerCalendarEventSnapshot: Equatable {
    let identifier: String
    let title: String
    let start: Date
    let end: Date
    let notes: String?
    let url: URL?
}

struct PlannerCalendarSyncPlan: Equatable {
    struct Upsert: Equatable {
        let block: PlannerCalendarBlock
        let existingIdentifier: String?
    }

    let upserts: [Upsert]
    let deletions: [String]
}

enum PlannerCalendarSync {
    static let plannerSource = "planner"
    static let metadataStart = "[ItoriPlanner]"
    static let metadataEnd = "[/ItoriPlanner]"
    static let metadataURLScheme = "itori"

    static func buildBlocks(
        from sessions: [StoredScheduledSession],
        gapMinutes: Int,
        calendar: Calendar = .current,
        timeZone: TimeZone = .current
    ) -> [PlannerCalendarBlock] {
        guard !sessions.isEmpty else { return [] }
        let ordered = sessions.sorted { $0.start < $1.start }
        let gapThreshold = TimeInterval(gapMinutes * 60)
        let formatter = dayKeyFormatter(timeZone: timeZone)

        var blocks: [PlannerCalendarBlock] = []
        var currentDayKey: String?
        var currentStart: Date?
        var currentEnd: Date?
        var currentSessions: [StoredScheduledSession] = []

        func flush() {
            guard let dayKey = currentDayKey,
                  let start = currentStart,
                  let end = currentEnd else { return }
            let title = calendarTitle(for: currentSessions)
            let notes = buildNotes(
                kind: title,
                dayKey: dayKey,
                start: start,
                end: end,
                sessions: currentSessions,
                calendar: calendar,
                timeZone: timeZone
            )
            let blockId = blockIdFor(
                kind: title,
                dayKey: dayKey,
                start: start,
                end: end,
                sessions: currentSessions,
                calendar: calendar,
                timeZone: timeZone
            )
            blocks.append(PlannerCalendarBlock(
                id: blockId,
                title: title,
                start: start,
                end: end,
                notes: notes,
                dayKey: dayKey
            ))
            currentDayKey = nil
            currentStart = nil
            currentEnd = nil
            currentSessions.removeAll()
        }

        for session in ordered {
            let start = session.start
            let end = session.end
            let dayKey = formatter.string(from: start)
            if currentDayKey == nil {
                currentDayKey = dayKey
                currentStart = start
                currentEnd = end
                currentSessions = [session]
                continue
            }

            if currentDayKey != dayKey {
                flush()
                currentDayKey = dayKey
                currentStart = start
                currentEnd = end
                currentSessions = [session]
                continue
            }

            let gap = start.timeIntervalSince(currentEnd ?? start)
            if gap >= 0 && gap <= gapThreshold {
                currentEnd = max(currentEnd ?? end, end)
                currentSessions.append(session)
            } else {
                flush()
                currentStart = start
                currentEnd = end
                currentSessions = [session]
            }
        }
        flush()
        return blocks
    }

    static func syncPlan(
        blocks: [PlannerCalendarBlock],
        existingEvents: [PlannerCalendarEventSnapshot],
        range: ClosedRange<Date>
    ) -> PlannerCalendarSyncPlan {
        let blockIds = Set(blocks.map(\.id))
        let existingMetadata = existingEvents.compactMap { event -> (
            PlannerCalendarEventSnapshot,
            PlannerCalendarMetadata
        )? in
            guard let metadata = parseMetadata(notes: event.notes, url: event.url) else { return nil }
            return (event, metadata)
        }

        var seenBlockIds = Set<String>()
        var upserts: [PlannerCalendarSyncPlan.Upsert] = []

        for block in blocks {
            if let match = existingMetadata.first(where: { $0.1.blockId == block.id }) {
                seenBlockIds.insert(block.id)
                if match.0.title != block.title ||
                    match.0.start != block.start ||
                    match.0.end != block.end ||
                    match.0.notes != block.notes
                {
                    upserts.append(.init(block: block, existingIdentifier: match.0.identifier))
                }
            } else {
                upserts.append(.init(block: block, existingIdentifier: nil))
            }
        }

        var deletions: [String] = []
        for (event, metadata) in existingMetadata {
            guard metadata.source == plannerSource,
                  !metadata.blockId.isEmpty,
                  range.contains(event.start) || range.contains(event.end) else { continue }
            if blockIds.contains(metadata.blockId) {
                if seenBlockIds.contains(metadata.blockId) {
                    deletions.append(event.identifier)
                } else {
                    seenBlockIds.insert(metadata.blockId)
                }
                continue
            }
            deletions.append(event.identifier)
        }

        return PlannerCalendarSyncPlan(upserts: upserts, deletions: deletions)
    }

    static func parseMetadata(notes: String?, url: URL?) -> PlannerCalendarMetadata? {
        if let url, let metadata = parseMetadata(from: url) {
            return metadata
        }
        guard let notes, let metadata = parseMetadata(from: notes) else { return nil }
        return metadata
    }

    private static func parseMetadata(from url: URL) -> PlannerCalendarMetadata? {
        guard url.scheme == metadataURLScheme else { return nil }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let items = components.queryItems ?? []
        let blockId = items.first(where: { $0.name == "block_id" })?.value ?? ""
        let source = items.first(where: { $0.name == "source" })?.value ?? ""
        let dayKey = items.first(where: { $0.name == "day_key" })?.value ?? ""
        guard !blockId.isEmpty, !source.isEmpty, !dayKey.isEmpty else { return nil }
        return PlannerCalendarMetadata(blockId: blockId, source: source, dayKey: dayKey)
    }

    private static func parseMetadata(from notes: String) -> PlannerCalendarMetadata? {
        guard let start = notes.range(of: metadataStart),
              let end = notes.range(of: metadataEnd) else { return nil }
        let block = notes[start.upperBound ..< end.lowerBound]
        var blockId = ""
        var source = ""
        var dayKey = ""
        for line in block.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }
            switch parts[0].lowercased() {
            case "block_id":
                blockId = parts[1]
            case "source":
                source = parts[1]
            case "day_key":
                dayKey = parts[1]
            default:
                continue
            }
        }
        guard !blockId.isEmpty, !source.isEmpty, !dayKey.isEmpty else { return nil }
        return PlannerCalendarMetadata(blockId: blockId, source: source, dayKey: dayKey)
    }

    private static func buildNotes(
        kind _: String,
        dayKey _: String,
        start _: Date,
        end _: Date,
        sessions: [StoredScheduledSession],
        calendar _: Calendar,
        timeZone _: TimeZone
    ) -> String {
        let tasksById = Dictionary(uniqueKeysWithValues: AssignmentsStore.shared.tasks.map { ($0.id, $0) })
        let orderedSessions = sessions.sorted { $0.start < $1.start }
        var seenKeys = Set<String>()
        var dueItems: [String] = []
        var completedItems: [String] = []
        let dueFormatter = LocaleFormatters.dateAndTime

        for session in orderedSessions {
            let assignmentId = session.assignmentId
            let key = assignmentId?.uuidString ?? session.id.uuidString
            guard !seenKeys.contains(key) else { continue }
            seenKeys.insert(key)

            let title: String
            let dueDate: Date
            let isCompleted: Bool

            if let assignmentId, let task = tasksById[assignmentId] {
                title = task.title
                dueDate = task.effectiveDueDateTime ?? task.due ?? session.dueDate
                isCompleted = task.isCompleted
            } else {
                title = session.title
                dueDate = session.dueDate
                isCompleted = false
            }

            if isCompleted {
                completedItems.append("- \(title)")
            } else {
                let dueText = dueFormatter.string(from: dueDate)
                dueItems.append("- \(title) (Due: \(dueText))")
            }
        }

        let dueHeader = NSLocalizedString(
            "planner.calendar.notes.due",
            value: "Due:",
            comment: "Planner calendar notes due section"
        )
        let completedHeader = NSLocalizedString(
            "planner.calendar.notes.completed",
            value: "Completed:",
            comment: "Planner calendar notes completed section"
        )
        let lines = [dueHeader] + dueItems + ["", completedHeader] + completedItems
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func metadataBlock(
        kind: String,
        dayKey: String,
        start: Date,
        end: Date,
        sessions: [StoredScheduledSession],
        calendar: Calendar,
        timeZone: TimeZone
    ) -> String {
        let blockId = blockIdFor(
            kind: kind,
            dayKey: dayKey,
            start: start,
            end: end,
            sessions: sessions,
            calendar: calendar,
            timeZone: timeZone
        )
        let items = sessions.sorted { $0.start < $1.start }.map { session in
            let assignmentId = session.assignmentId?.uuidString ?? "none"
            return "\(assignmentId):\(session.id.uuidString)"
        }.joined(separator: ",")
        return """
        \(metadataStart)
        block_id: \(blockId)
        source: \(plannerSource)
        day_key: \(dayKey)
        kind: \(kind)
        start: \(isoFormatter(timeZone: timeZone).string(from: start))
        end: \(isoFormatter(timeZone: timeZone).string(from: end))
        items: \(items)
        \(metadataEnd)
        """
    }

    static func metadataURL(for block: PlannerCalendarBlock) -> URL? {
        var components = URLComponents()
        components.scheme = metadataURLScheme
        components.path = "/planner"
        components.queryItems = [
            URLQueryItem(name: "block_id", value: block.id),
            URLQueryItem(name: "source", value: plannerSource),
            URLQueryItem(name: "day_key", value: block.dayKey)
        ]
        return components.url
    }

    private static func blockIdFor(
        kind: String,
        dayKey: String,
        start: Date,
        end: Date,
        sessions: [StoredScheduledSession],
        calendar: Calendar,
        timeZone: TimeZone
    ) -> String {
        let roundedStart = roundedDate(start, calendar: calendar, incrementMinutes: 5)
        let roundedEnd = roundedDate(end, calendar: calendar, incrementMinutes: 5)
        let items = sessions.sorted { $0.start < $1.start }.map { session in
            let assignmentId = session.assignmentId?.uuidString ?? "none"
            return "\(assignmentId):\(session.id.uuidString)"
        }.joined(separator: ",")
        let payload = "day=\(dayKey)|kind=\(kind)|start=\(isoFormatter(timeZone: timeZone).string(from: roundedStart))|end=\(isoFormatter(timeZone: timeZone).string(from: roundedEnd))|items=\(items)"
        return sha256(payload)
    }

    private static func calendarTitle(for sessions: [StoredScheduledSession]) -> String {
        let categories = Set(sessions.compactMap(\.category))
        if categories.count == 1, let category = categories.first {
            let base = switch category {
            case .homework: "Homework"
            case .reading: "Reading"
            case .review: "Review"
            case .exam: "Exam"
            case .quiz: "Quiz"
            case .project: "Project"
            case .practiceTest: "Practice Test"
            }
            return "\(base) Session"
        }
        return "Coursework Session"
    }

    private static func durationString(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        }
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(max(0, minutes))m"
    }

    private static func roundedDate(_ date: Date, calendar _: Calendar, incrementMinutes: Int) -> Date {
        let seconds = date.timeIntervalSinceReferenceDate
        let increment = TimeInterval(incrementMinutes * 60)
        let rounded = (seconds / increment).rounded() * increment
        return Date(timeIntervalSinceReferenceDate: rounded)
    }

    private static func dayKeyFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private static func isoFormatter(timeZone: TimeZone) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = timeZone
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    private static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
