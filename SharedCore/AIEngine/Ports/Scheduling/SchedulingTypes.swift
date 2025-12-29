import Foundation

public struct SleepWindow: Codable, Sendable, Hashable {
    public let startHour: Int
    public let endHour: Int

    public init(startHour: Int = 23, endHour: Int = 7) {
        self.startHour = startHour
        self.endHour = endHour
    }
}

public struct ScheduleFixedEvent: Codable, Sendable, Hashable {
    public let title: String
    public let start: Date
    public let end: Date

    public init(title: String, start: Date, end: Date) {
        self.title = title
        self.start = start
        self.end = end
    }
}

public enum StudyTimePreference: String, Codable, Sendable, Hashable {
    case morning
    case afternoon
    case evening
    case balanced
}
