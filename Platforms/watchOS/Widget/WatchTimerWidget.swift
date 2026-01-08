#if canImport(WidgetKit)
import SwiftUI
import WidgetKit

enum AppGroupConstants {
    static let identifier = "group.com.cwlewisiii.Itori"
    static let watchTimerStateKey = "watchTimerState"
}

struct WatchTimerEntry: TimelineEntry {
    let date: Date
    let state: WatchTimerStateSnapshot?
}

struct WatchTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchTimerEntry {
        WatchTimerEntry(date: Date(), state: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchTimerEntry) -> Void) {
        completion(WatchTimerEntry(date: Date(), state: loadState()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchTimerEntry>) -> Void) {
        let entry = WatchTimerEntry(date: Date(), state: loadState())
        let next = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date().addingTimeInterval(60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadState() -> WatchTimerStateSnapshot? {
        guard let defaults = UserDefaults(suiteName: AppGroupConstants.identifier),
              let data = defaults.data(forKey: AppGroupConstants.watchTimerStateKey),
              let state = try? JSONDecoder().decode(WatchTimerStateSnapshot.self, from: data) else {
            return nil
        }
        return state
    }
}

struct WatchTimerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WatchTimerWidget", provider: WatchTimerProvider()) { entry in
            WatchTimerWidgetView(entry: entry)
        }
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
        .configurationDisplayName("Timer")
        .description("Shows your running timer on the watch face or Smart Stack.")
    }
}

struct WatchTimerWidgetView: View {
    let entry: WatchTimerEntry

    var body: some View {
        switch entry.state {
        case .some(let state):
            WatchTimerContent(state: state)
        case .none:
            Text("No Timer")
                .font(.caption)
        }
    }
}

struct WatchTimerContent: View {
    let state: WatchTimerStateSnapshot

    private var timeString: String {
        let minutes = max(state.remainingSeconds, 0) / 60
        let seconds = max(state.remainingSeconds, 0) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if state.isRunning {
                Text(timeString)
                    .font(.headline)
                Text(state.modeRaw.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("Paused")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct WatchTimerStateSnapshot: Codable {
    let isRunning: Bool
    let isPaused: Bool
    let modeRaw: String
    let remainingSeconds: Int
    let startedAtISO: String?
}
#endif
