import Foundation

/// Canonical recurrence rule for repeating tasks.
/// Single source of truth - replaces any competing recurrence types.
public struct RecurrenceRule: Codable, Equatable, Hashable, Sendable {
    public enum Frequency: String, Codable, Sendable {
        case daily
        case weekly
        case monthly
        case yearly
    }

    public enum End: Codable, Equatable, Hashable, Sendable {
        case never
        case afterOccurrences(Int)
        case until(Date)

        // Convenience for readability
        public static func onDate(_ date: Date) -> End {
            .until(date)
        }
    }

    public enum HolidaySource: String, Codable, Sendable {
        case none
        case deviceCalendar
        case usaFederal
        case custom
    }

    public enum Adjustment: String, Codable, Sendable {
        case forward
    }

    public struct SkipPolicy: Codable, Equatable, Hashable, Sendable {
        public var skipWeekends: Bool
        public var skipHolidays: Bool
        public var holidaySource: HolidaySource
        public var adjustment: Adjustment

        public init(
            skipWeekends: Bool = false,
            skipHolidays: Bool = false,
            holidaySource: HolidaySource = .none,
            adjustment: Adjustment = .forward
        ) {
            self.skipWeekends = skipWeekends
            self.skipHolidays = skipHolidays
            self.holidaySource = holidaySource
            self.adjustment = adjustment
        }
    }

    public let frequency: Frequency
    public let interval: Int // Must be >= 1
    public let end: End
    public let skipPolicy: SkipPolicy

    public init(frequency: Frequency, interval: Int, end: End, skipPolicy: SkipPolicy) {
        self.frequency = frequency
        self.interval = max(1, interval) // Enforce minimum
        self.end = end
        self.skipPolicy = skipPolicy
    }

    /// Preset recurrence rules for common patterns
    public static func preset(_ frequency: Frequency) -> RecurrenceRule {
        RecurrenceRule(frequency: frequency, interval: 1, end: .never, skipPolicy: SkipPolicy())
    }

    /// Calculate next due date from a base date
    public func nextDueDate(from baseDate: Date) -> Date? {
        let calendar = Calendar.current
        let component: Calendar.Component = switch frequency {
        case .daily:
            .day
        case .weekly:
            .weekOfYear
        case .monthly:
            .month
        case .yearly:
            .year
        }

        return calendar.date(byAdding: component, value: interval, to: baseDate)
    }
}
