import SwiftUI
import EventKit

struct CalendarDayView: View {
    var date: Date
    var events: [EKEvent]
    var onSelectEvent: ((EKEvent) -> Void)? = nil

    private let calendar = Calendar.current
    private let hours = Array(0...23)

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(hours, id: \.self) { hour in
                    HStack(alignment: .top, spacing: 12) {
                        Text(hourLabel(hour))
                            .font(.caption)
                            .frame(width: 50, alignment: .trailing)
                            .foregroundStyle(.secondary)

                        ZStack(alignment: .topLeading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.08))
                                .frame(height: 60)

                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(eventsAt(hour: hour), id: \.rootsIdentifier) { event in
                                    Button {
                                        onSelectEvent?(event)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(categoryLabel(for: event.title))
                                                .font(.caption2.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            Text(event.title)
                                                .font(.caption2)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(6)
                                        .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(6)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return date.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated)))
    }

    private func eventsAt(hour: Int) -> [EKEvent] {
        events.filter {
            let eventHour = calendar.component(.hour, from: $0.startDate)
            return calendar.isDate($0.startDate, inSameDayAs: date) && eventHour == hour
        }
    }

    private func categoryLabel(for title: String) -> String {
        let lower = title.lowercased()
        let pairs: [(String, String)] = [
            ("exam", "Exam"),
            ("midterm", "Exam"),
            ("final", "Exam"),
            ("class", "Class"),
            ("lecture", "Class"),
            ("lab", "Class"),
            ("study", "Study"),
            ("read", "Reading"),
            ("homework", "Homework"),
            ("assignment", "Homework"),
            ("problem set", "Homework"),
            ("practice test", "Practice Test"),
            ("mock", "Practice Test"),
            ("quiz", "Practice Test"),
            ("meeting", "Meeting"),
            ("sync", "Meeting"),
            ("1:1", "Meeting"),
            ("one-on-one", "Meeting")
        ]
        for (key, label) in pairs {
            if lower.contains(key) { return label }
        }
        return "Other"
    }
}
