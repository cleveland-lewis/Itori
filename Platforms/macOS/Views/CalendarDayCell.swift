#if os(macOS)
import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let isInCurrentMonth: Bool
    let isSelected: Bool
    let eventCount: Int
    let calendar: Calendar

    private let cornerRadius: CGFloat = 12

    var body: some View {
        let isToday = calendar.isDateInToday(date)
        let a11yContent = VoiceOverLabels.dateCell(date: date, eventCount: eventCount)

        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)

            VStack(alignment: .leading, spacing: 0) {
                Text(dayString)
                    .font(.system(size: 12, weight: isToday ? .semibold : .regular))
                    .foregroundColor(textColor(isToday: isToday))
                    .padding(6)
                    .background(
                        Group {
                            if isToday && !isSelected {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 20, height: 20)
                            }
                        }
                    )

                Spacer(minLength: 0)

                if eventCount > 0 {
                    EventDensityBar(level: densityLevel(for: eventCount))
                        .padding(.leading, 6)
                        .padding(.bottom, 6)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: isSelected ? 1.5 : 0)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .voiceOver(a11yContent)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var dayString: String {
        String(calendar.component(.day, from: date))
    }

    private func textColor(isToday: Bool) -> Color {
        if isSelected {
            return .white
        } else if !isInCurrentMonth {
            return .secondary.opacity(0.5)
        } else if isToday {
            return .white
        } else {
            return .primary
        }
    }

    private func densityLevel(for count: Int) -> EventDensityLevel {
        switch count {
        case 0: return .none
        case 1...3: return .low
        case 4...6: return .medium
        default: return .high
        }
    }
}

enum EventDensityLevel {
    case none, low, medium, high

    var color: Color {
        switch self {
        case .none: return Color.secondary.opacity(0.25)
        case .low: return RootsColor.calendarDensityLow
        case .medium: return RootsColor.calendarDensityMedium
        case .high: return RootsColor.calendarDensityHigh
        }
    }

    static func fromCount(_ count: Int) -> EventDensityLevel {
        switch count {
        case 0: return .none
        case 1...3: return .low
        case 4...6: return .medium
        default: return .high
        }
    }
}

struct EventDensityBar: View {
    var level: EventDensityLevel
    var body: some View {
        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(level.color)
            .frame(height: 5)
            .frame(maxWidth: 32)
    }
}

struct CalendarDayCell_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            CalendarDayCell(date: Date(), isInCurrentMonth: true, isSelected: false, eventCount: 0, calendar: Calendar.current)
            CalendarDayCell(date: Date(), isInCurrentMonth: true, isSelected: false, eventCount: 1, calendar: Calendar.current)
            CalendarDayCell(date: Date(), isInCurrentMonth: true, isSelected: false, eventCount: 3, calendar: Calendar.current)
            CalendarDayCell(date: Date(), isInCurrentMonth: true, isSelected: true, eventCount: 5, calendar: Calendar.current)
        }
        .preferredColorScheme(.dark)
        .padding(DesignSystem.Layout.padding.card)
        .background(Color.black)
    }
}
#endif
