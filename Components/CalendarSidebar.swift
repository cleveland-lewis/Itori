import SwiftUI

// Reuse CalendarEvent as CalendarItem
public typealias CalendarItem = CalendarEvent

public struct CalendarSidebarView: View {
    let selectedDate: Date
    let events: [CalendarItem]
    let onSelectEvent: (CalendarItem) -> Void

    private let calendar = Calendar.current

    var body: some View {
        RootsCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(sectionHeader)
                    .rootsSectionHeader()
                    .foregroundColor(RootsColor.textPrimary)

                Divider()

                if events.isEmpty {
                    Text("No events")
                        .rootsBodySecondary()
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(events) { event in
                                EventRow(item: event) {
                                    onSelectEvent(event)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(12)
        }
        .frame(minWidth: RootsWindowLayout.sidebarWidth, maxWidth: RootsWindowLayout.sidebarWidth + 40)
    }

    private var sectionHeader: String {
        let fmt = DateFormatter(); fmt.dateFormat = "E, MMM d"
        return fmt.string(from: selectedDate)
    }
}

public struct EventRow: View {
    let item: CalendarItem
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Text(timeString)
                    .rootsCaption()
                    .foregroundColor(.secondary)
                    .frame(width: 56, alignment: .trailing)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .rootsBody()
                        .fontWeight(.semibold)
                        .foregroundColor(RootsColor.textPrimary)
                    if let location = item.location, !location.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(location)
                                .rootsCaption()
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
            }
            .padding(10)
            .background(hovering ? Color.primary.opacity(0.03) : Color.clear)
            .cornerRadius(8)
        }
        .onHover { hovering = $0 }
    }

    private var timeString: String {
        let f = DateFormatter(); f.dateFormat = AppSettingsModel.shared.use24HourTime ? "HH:mm" : "h:mm a"
        return f.string(from: item.startDate)
    }
}

public struct EventDetailView: View {
    let item: CalendarItem
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.title)
                .rootsTitle()

            VStack(alignment: .leading, spacing: 6) {
                Text(dateRange)
                    .rootsBodySecondary()
                if let location = item.location, !location.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                        Text(location)
                            .rootsBodySecondary()
                    }
                }
            }

            if let notes = item.notes, !notes.isEmpty {
                ScrollView {
                    Text(notes)
                        .rootsBody()
                        .foregroundColor(RootsColor.textPrimary)
                        .padding(12)
                        .background(DesignSystem.Materials.card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .frame(maxHeight: 240)
            }

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 400, minHeight: 300)
    }
}
