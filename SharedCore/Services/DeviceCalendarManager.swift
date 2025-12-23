import Foundation
import EventKit
import Combine

@MainActor
final class DeviceCalendarManager: ObservableObject {
    static let shared = DeviceCalendarManager()

    let store = EKEventStore()

    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var events: [EKEvent] = []
    
    /// Events with optimistic updates applied (computed from `events` + OptimisticEventStore)
    @Published private(set) var displayEvents: [EKEvent] = []

    @Published private(set) var lastRefreshAt: Date? = nil
    @Published private(set) var isObservingStoreChanges: Bool = false
    @Published private(set) var lastRefreshReason: String? = nil

    private var storeChangedObserver: Any?
    private var optimisticStoreObserver: AnyCancellable?

    private init() {
        // Observe optimistic store changes to recompute display events
        optimisticStoreObserver = OptimisticEventStore.shared.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in
                self?.recomputeDisplayEvents()
            }
        }
    }

    func bootstrapOnLaunch() async {
        let granted = await requestFullAccessIfNeeded()
        await MainActor.run { self.isAuthorized = granted }
        guard granted else { return }

        startObservingStoreChanges()
        await refreshEventsForVisibleRange(reason: "launch")
    }

    func refreshEventsForVisibleRange(reason: String = "rangeRefresh") async {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -30, to: .now)!
        let end   = cal.date(byAdding: .day, value:  90, to: .now)!

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let fetched = store.events(matching: predicate)

        await MainActor.run {
            self.events = fetched
            self.lastRefreshAt = Date()
            self.lastRefreshReason = reason
            self.recomputeDisplayEvents()
        }
    }

    func requestFullAccessIfNeeded() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .fullAccess:
            return true
        case .writeOnly:
            return true
        case .notDetermined:
            if #available(macOS 14.0, *) {
                do {
                    return try await store.requestFullAccessToEvents()
                } catch {
                    return false
                }
            } else {
                return await withCheckedContinuation { cont in
                    store.requestAccess(to: .event) { granted, _ in cont.resume(returning: granted) }
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func refreshEventsForVisibleRange() async {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -30, to: .now)!
        let end   = cal.date(byAdding: .day, value:  90, to: .now)!

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let fetched = store.events(matching: predicate)

        await MainActor.run {
            self.events = fetched
            self.recomputeDisplayEvents()
        }
    }

    func refreshEvents(in range: DateInterval, reason: String = "targetedRefresh") async {
        let predicate = store.predicateForEvents(withStart: range.start, end: range.end, calendars: nil)
        let fetched = store.events(matching: predicate)

        await MainActor.run {
            self.events.removeAll { event in
                let start = event.startDate
                let end = event.endDate
                return start < range.end && end > range.start
            }
            self.events.append(contentsOf: fetched)
            self.lastRefreshAt = Date()
            self.lastRefreshReason = reason
            self.recomputeDisplayEvents()
        }
    }

    func startObservingStoreChanges() {
        guard storeChangedObserver == nil else { return }

        storeChangedObserver = NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            Task { await self.refreshEventsForVisibleRange(reason: "storeChanged") }
        }

        isObservingStoreChanges = true
    }
    
    /// Merges real EventKit events with optimistic updates to produce display events
    private func recomputeDisplayEvents() {
        let optimisticStore = OptimisticEventStore.shared
        
        // Create a copy of events with optimistic updates applied
        displayEvents = events.map { event in
            guard let identifier = event.eventIdentifier,
                  !identifier.isEmpty,
                  let optimistic = optimisticStore.optimisticEvent(for: identifier) else {
                return event
            }
            
            // Apply optimistic changes to a copy
            let updated = event.copy() as! EKEvent
            if let title = optimistic.title {
                updated.title = title
            }
            if let start = optimistic.startDate {
                updated.startDate = start
            }
            if let end = optimistic.endDate {
                updated.endDate = end
            }
            if let isAllDay = optimistic.isAllDay {
                updated.isAllDay = isAllDay
            }
            if let location = optimistic.location {
                updated.location = location
            }
            if let notes = optimistic.notes {
                updated.notes = notes
            }
            if let urlString = optimistic.url, let url = URL(string: urlString) {
                updated.url = url
            }
            
            return updated
        }
    }
}
