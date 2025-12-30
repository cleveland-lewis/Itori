import SwiftUI

enum DashboardSlot: CaseIterable {
    case today
    case upcoming
    case energy
    case assignments
    case studyHours
    case plannerToday
    case workRemaining
    case calendar
}

struct SlotSpec {
    let columns: (wide: Int, medium: Int, narrow: Int)
    let minHeightCompact: CGFloat
    let minHeightFull: CGFloat

    func span(for mode: ColumnMode) -> Int {
        switch mode {
        case .four:
            return columns.wide
        case .two:
            return columns.medium
        case .one:
            return columns.narrow
        }
    }

    func minHeight(for mode: DashboardCardMode) -> CGFloat {
        mode == .compactEmpty ? minHeightCompact : minHeightFull
    }
}

enum ColumnMode: Int {
    case one = 1
    case two = 2
    case four = 4

    init(width: CGFloat) {
        if width < 700 {
            self = .one
        } else if width < 1100 {
            self = .two
        } else {
            self = .four
        }
    }
}

enum DashboardLayoutSpec {
    static let spec: [DashboardSlot: SlotSpec] = [
        .today: SlotSpec(columns: (wide: 2, medium: 2, narrow: 1), minHeightCompact: 110, minHeightFull: 260),
        .upcoming: SlotSpec(columns: (wide: 2, medium: 2, narrow: 1), minHeightCompact: 110, minHeightFull: 240),
        .energy: SlotSpec(columns: (wide: 2, medium: 2, narrow: 1), minHeightCompact: 110, minHeightFull: 220),
        .assignments: SlotSpec(columns: (wide: 2, medium: 2, narrow: 1), minHeightCompact: 110, minHeightFull: 240),
        .studyHours: SlotSpec(columns: (wide: 4, medium: 2, narrow: 1), minHeightCompact: 110, minHeightFull: 220),
        .plannerToday: SlotSpec(columns: (wide: 1, medium: 1, narrow: 1), minHeightCompact: 110, minHeightFull: 220),
        .workRemaining: SlotSpec(columns: (wide: 1, medium: 1, narrow: 1), minHeightCompact: 110, minHeightFull: 220),
        .calendar: SlotSpec(columns: (wide: 2, medium: 2, narrow: 1), minHeightCompact: 110, minHeightFull: 260)
    ]

    static func span(for slot: DashboardSlot, mode: ColumnMode) -> Int {
        guard let spec = spec[slot] else {
            assertionFailure("Missing slot spec for \(slot)")
            return 1
        }
        return spec.span(for: mode)
    }

    static func minHeight(for slot: DashboardSlot, mode: DashboardCardMode) -> CGFloat {
        guard let spec = spec[slot] else {
            assertionFailure("Missing slot spec for \(slot)")
            return 200
        }
        return spec.minHeight(for: mode)
    }

    static func rows(for mode: ColumnMode) -> [[DashboardSlot]] {
        rows(for: mode, slots: DashboardSlot.allCases)
    }

    static func rows(for mode: ColumnMode, slots: [DashboardSlot]) -> [[DashboardSlot]] {
        let capacity = mode.rawValue
        var rows: [[DashboardSlot]] = []
        var currentRow: [DashboardSlot] = []
        var currentWidth = 0

        for slot in slots {
            let span = max(1, span(for: slot, mode: mode))
            if currentWidth + span > capacity {
                rows.append(currentRow)
                currentRow = []
                currentWidth = 0
            }
            currentRow.append(slot)
            currentWidth += span
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

#if DEBUG
    static func validate(for mode: ColumnMode) {
        let allSlots = DashboardSlot.allCases
        let slotKeys = Set(spec.keys)
        let allSlotKeys = Set(allSlots)

        assert(spec.count == allSlots.count, "DashboardLayoutSpec: spec count mismatch.")
        assert(slotKeys == allSlotKeys, "DashboardLayoutSpec: spec keys mismatch.")

        for slot in allSlots {
            let span = span(for: slot, mode: mode)
            assert(span >= 1 && span <= mode.rawValue, "DashboardLayoutSpec: invalid span \(span) for \(slot).")
        }

        let rows = rows(for: mode)
        var seen: [DashboardSlot] = []
        for (index, row) in rows.enumerated() {
            let total = row.reduce(0) { $0 + span(for: $1, mode: mode) }
            let isLast = index == rows.count - 1
            if isLast {
                assert(total <= mode.rawValue, "DashboardLayoutSpec: row exceeds capacity.")
            } else {
                assert(total == mode.rawValue, "DashboardLayoutSpec: row does not fill capacity.")
            }
            seen.append(contentsOf: row)
        }

        assert(Set(seen) == allSlotKeys, "DashboardLayoutSpec: missing or extra slots.")
        assert(seen.count == allSlots.count, "DashboardLayoutSpec: duplicate slots detected.")
    }
#endif
}
