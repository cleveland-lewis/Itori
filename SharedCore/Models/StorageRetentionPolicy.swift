import Foundation

public enum StorageRetentionPolicy: String, CaseIterable, Identifiable, Codable {
    case never
    case semester30Days
    case semester90Days
    case oneYear
    case twoYears

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .never: "Never Delete"
        case .semester30Days: "30 Days After Semester"
        case .semester90Days: "90 Days After Semester"
        case .oneYear: "1 Year"
        case .twoYears: "2 Years"
        }
    }

    public var detail: String {
        switch self {
        case .never:
            "Keep all detailed data."
        case .semester30Days:
            "Remove detailed data 30 days after a semester ends."
        case .semester90Days:
            "Remove detailed data 90 days after a semester ends."
        case .oneYear:
            "Remove detailed data after 1 year."
        case .twoYears:
            "Remove detailed data after 2 years."
        }
    }

    public var isSemesterBased: Bool {
        switch self {
        case .semester30Days, .semester90Days: true
        case .never, .oneYear, .twoYears: false
        }
    }

    public func isExpired(primaryDate: Date, semesterEnd: Date?, now: Date = Date()) -> Bool {
        switch self {
        case .never:
            return false
        case .semester30Days:
            let endDate = semesterEnd ?? primaryDate
            return now >= Calendar.current.date(byAdding: .day, value: 30, to: endDate) ?? now
        case .semester90Days:
            let endDate = semesterEnd ?? primaryDate
            return now >= Calendar.current.date(byAdding: .day, value: 90, to: endDate) ?? now
        case .oneYear:
            return now >= Calendar.current.date(byAdding: .year, value: 1, to: primaryDate) ?? now
        case .twoYears:
            return now >= Calendar.current.date(byAdding: .year, value: 2, to: primaryDate) ?? now
        }
    }
}
