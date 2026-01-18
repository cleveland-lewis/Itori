import Foundation

extension DateFormatter {
    /// Returns a DateFormatter configured to respect the user's 24-hour time preference
    static func itoriTimeFormatter(includeMinutes: Bool = true) -> DateFormatter {
        let formatter = DateFormatter()
        let use24Hour = AppSettingsModel.shared.use24HourTime

        if includeMinutes {
            formatter.dateFormat = use24Hour ? "HH:mm" : "h:mm a"
        } else {
            formatter.dateFormat = use24Hour ? "HH" : "h a"
        }

        return formatter
    }

    /// Returns a DateFormatter configured for short time style respecting user preference
    static var itoriShortTime: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        // Override the time format if user wants 24-hour time
        if AppSettingsModel.shared.use24HourTime {
            formatter.dateFormat = "HH:mm"
        }

        return formatter
    }

    /// Returns a DateFormatter configured for medium time style respecting user preference
    static var itoriMediumTime: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium

        // Override the time format if user wants 24-hour time
        if AppSettingsModel.shared.use24HourTime {
            formatter.dateFormat = "HH:mm:ss"
        }

        return formatter
    }
}

extension Date {
    /// Formats the time portion of this date respecting user's 24-hour preference
    func formattedTime(includeMinutes: Bool = true) -> String {
        DateFormatter.itoriTimeFormatter(includeMinutes: includeMinutes).string(from: self)
    }

    /// Formats this date with short time style respecting user's 24-hour preference
    var shortTimeString: String {
        DateFormatter.itoriShortTime.string(from: self)
    }

    /// Formats this date with medium time style respecting user's 24-hour preference
    var mediumTimeString: String {
        DateFormatter.itoriMediumTime.string(from: self)
    }
}
