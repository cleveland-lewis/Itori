import SwiftUI

struct PendingScheduleSuggestionStrip: View {
    let pending: PendingScheduleSuggestion
    let onApply: () -> Void
    let onApplyNonConflicting: () -> Void
    let onDismiss: () -> Void

    @State private var isExpanded = false

    var body: some View {
        let diff = pending.diff
        let totalChanges = diff.changeCount
        let nonConflictingDiff = diff.nonConflictingChanges
        let nonConflictingChanges = nonConflictingDiff.changeCount
        let hasConflicts = !diff.conflicts.isEmpty

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Schedule suggestions ready")
                        .font(.headline)

                    Text(pending.summaryText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(isExpanded ? "Hide" : "Preview") { isExpanded.toggle() }
                    .buttonStyle(.bordered)

                if hasConflicts {
                    if nonConflictingChanges > 0 {
                        Button("Apply Non-Conflicting") { onApplyNonConflicting() }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    Button("Apply (\(totalChanges) changes)") { onApply() }
                        .buttonStyle(.borderedProminent)
                }
            }

            if isExpanded {
                ScheduleDiffPreview(diff: pending.diff)
            }

            if hasConflicts {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Conflicts (\(diff.conflicts.count))")
                        .font(.subheadline.weight(.semibold))
                    ForEach(diff.conflictItemsSortedForDisplay) { item in
                        Text(item.displayLine)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack {
                Button("Dismiss") { onDismiss() }
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ScheduleDiffPreview: View {
    let diff: ScheduleDiff

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(diff.itemsSortedForDisplay) { item in
                Text(item.displayLine)
                    .font(.callout)
            }
        }
        .padding(.top, 4)
    }
}

struct ScheduleDiffDisplayItem: Identifiable, Equatable {
    let id: String
    let startDate: Date?
    let displayLine: String
}

struct ScheduleConflictDisplayItem: Identifiable, Equatable {
    let id: String
    let sortDate: Date?
    let sortTag: String
    let displayLine: String
}

extension ScheduleDiff {
    var changeCount: Int {
        addedBlocks.count + movedBlocks.count + resizedBlocks.count + removedBlocks.count
    }

    var nonConflictingChanges: ScheduleDiff {
        let blockedIDs = Set(
            conflicts.flatMap { [$0.blockID, $0.conflictingBlockID] }.compactMap { $0 }
        )
        return ScheduleDiff(
            addedBlocks: addedBlocks.filter { !blockedIDs.contains($0.tempID) },
            movedBlocks: movedBlocks.filter { !blockedIDs.contains($0.blockID) },
            resizedBlocks: resizedBlocks.filter { !blockedIDs.contains($0.blockID) },
            removedBlocks: removedBlocks.filter { !blockedIDs.contains($0.blockID) },
            conflicts: [],
            reason: reason,
            confidence: confidence
        )
    }

    var itemsSortedForDisplay: [ScheduleDiffDisplayItem] {
        var items: [ScheduleDiffDisplayItem] = []
        let formatter = ScheduleDiffDisplayFormatter.shared

        for block in addedBlocks {
            let line = formatter.line(
                startDate: block.startDate,
                duration: block.duration,
                title: block.title
            )
            items.append(ScheduleDiffDisplayItem(
                id: "add-\(block.tempID)",
                startDate: block.startDate,
                displayLine: line
            ))
        }

        for move in movedBlocks {
            let line = "Move block \(move.blockID) to \(formatter.timeOnly(move.newStartDate))"
            items.append(ScheduleDiffDisplayItem(
                id: "move-\(move.blockID)",
                startDate: move.newStartDate,
                displayLine: line
            ))
        }

        for resize in resizedBlocks {
            let minutes = Int(resize.newDuration / 60.0)
            let line = "Resize block \(resize.blockID) to \(minutes) min"
            items.append(ScheduleDiffDisplayItem(
                id: "resize-\(resize.blockID)",
                startDate: nil,
                displayLine: line
            ))
        }

        return items.sorted { lhs, rhs in
            let leftDate = lhs.startDate ?? Date.distantFuture
            let rightDate = rhs.startDate ?? Date.distantFuture
            if leftDate != rightDate {
                return leftDate < rightDate
            }
            return lhs.id < rhs.id
        }
    }

    var conflictItemsSortedForDisplay: [ScheduleConflictDisplayItem] {
        let formatter = ScheduleDiffDisplayFormatter.shared
        let items = conflicts.map { conflict in
            let date = conflictDate(for: conflict)
            let line = formatter.conflictLine(date: date, blockID: conflict.blockID, reason: conflict.reason)
            return ScheduleConflictDisplayItem(
                id: conflict.id.uuidString,
                sortDate: date,
                sortTag: conflict.blockID,
                displayLine: line
            )
        }

        return items.sorted { lhs, rhs in
            let leftDate = lhs.sortDate ?? Date.distantFuture
            let rightDate = rhs.sortDate ?? Date.distantFuture
            if leftDate != rightDate {
                return leftDate < rightDate
            }
            return lhs.sortTag < rhs.sortTag
        }
    }

    private func conflictDate(for conflict: ScheduleConflict) -> Date? {
        if let date = dateForBlockID(conflict.blockID) {
            return date
        }
        if let other = conflict.conflictingBlockID,
           let date = dateForBlockID(other) {
            return date
        }
        return nil
    }

    private func dateForBlockID(_ blockID: String) -> Date? {
        if let added = addedBlocks.first(where: { $0.tempID == blockID }) {
            return added.startDate
        }
        if let moved = movedBlocks.first(where: { $0.blockID == blockID }) {
            return moved.newStartDate
        }
        return nil
    }
}

private final class ScheduleDiffDisplayFormatter {
    static let shared = ScheduleDiffDisplayFormatter()

    private let dayTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE h:mm a"
        return formatter
    }()

    private let timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    func line(startDate: Date, duration: TimeInterval, title: String) -> String {
        let endDate = startDate.addingTimeInterval(duration)
        let start = dayTimeFormatter.string(from: startDate)
        let end = timeOnlyFormatter.string(from: endDate)
        return "\(start)-\(end) - \(title)"
    }

    func timeOnly(_ date: Date) -> String {
        timeOnlyFormatter.string(from: date)
    }

    func conflictLine(date: Date?, blockID: String, reason: String) -> String {
        if let date {
            let start = dayTimeFormatter.string(from: date)
            return "\(start) • \(blockID) • \(reason)"
        }
        return "\(blockID) • \(reason)"
    }
}
