import Combine
import EventKit
import Foundation

@MainActor
final class DeviceCalendarManager: ObservableObject {
    static let shared = DeviceCalendarManager()

    let store = EKEventStore()
    private let authManager = CalendarAuthorizationManager.shared

    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var events: [EKEvent] = []

    @Published private(set) var lastRefreshAt: Date? = nil
    @Published private(set) var isObservingStoreChanges: Bool = false
    @Published private(set) var lastRefreshReason: String? = nil

    private var storeChangedObserver: Any?

    private init() {
        authManager.refreshStatus()
        isAuthorized = authManager.isAuthorized
        authManager.$eventStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.isAuthorized = self.authManager.isAuthorized
            }
            .store(in: &cancellables)
    }

    private var cancellables: Set<AnyCancellable> = []

    func bootstrapOnLaunch() async {
        authManager.refreshStatus()
        await MainActor.run { self.isAuthorized = authManager.isAuthorized }
        guard authManager.isAuthorized else { return }

        startObservingStoreChanges()
        await refreshEventsForVisibleRange(reason: "launch")
    }

    func refreshEventsForVisibleRange(reason: String = "rangeRefresh") async {
        // Check authorization before attempting to fetch
        guard authManager.isAuthorized else {
            authManager.logDeniedOnce(context: reason)
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.events = []
                self.lastRefreshAt = Date()
                self.lastRefreshReason = "\(reason) - unauthorized"
            }
            return
        }

        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -30, to: .now)!
        let end = cal.date(byAdding: .day, value: 90, to: .now)!

        // Filter by selected school calendar if one is set
        let calendarsToFetch: [EKCalendar]?
        let calendarID = AppSettingsModel.shared.selectedSchoolCalendarID
        if !calendarID.isEmpty,
           let selectedCalendar = store.calendar(withIdentifier: calendarID)
        {
            calendarsToFetch = [selectedCalendar]
        } else {
            calendarsToFetch = nil
        }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendarsToFetch)
        let fetched = store.events(matching: predicate)

        await MainActor.run { [weak self] in
            guard let self else { return }
            self.events = fetched
            self.lastRefreshAt = Date()
            self.lastRefreshReason = reason
        }
    }

    func refreshEvents(from start: Date, to end: Date, reason: String) async {
        // Check authorization before attempting to fetch
        guard authManager.isAuthorized else {
            authManager.logDeniedOnce(context: reason)
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.events = []
                self.lastRefreshAt = Date()
                self.lastRefreshReason = "\(reason) - unauthorized"
            }
            return
        }

        // Filter by selected school calendar if one is set
        let calendarsToFetch: [EKCalendar]?
        let calendarID = AppSettingsModel.shared.selectedSchoolCalendarID
        if !calendarID.isEmpty,
           let selectedCalendar = store.calendar(withIdentifier: calendarID)
        {
            calendarsToFetch = [selectedCalendar]
        } else {
            calendarsToFetch = nil
        }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendarsToFetch)
        let fetched = store.events(matching: predicate)

        await MainActor.run { [weak self] in
            guard let self else { return }
            self.events = fetched
            self.lastRefreshAt = Date()
            self.lastRefreshReason = reason
        }
    }

    func requestFullAccessIfNeeded() async -> Bool {
        let granted = await authManager.requestAccess(using: store)
        await MainActor.run { [weak self] in
            self?.isAuthorized = granted
        }
        return granted
    }

    func refreshEventsForVisibleRange() async {
        // Check authorization before attempting to fetch
        guard authManager.isAuthorized else {
            authManager.logDeniedOnce(context: "rangeRefresh")
            await MainActor.run { [weak self] in
                self?.events = []
            }
            return
        }

        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -30, to: .now)!
        let end = cal.date(byAdding: .day, value: 90, to: .now)!

        // Filter by selected school calendar if one is set
        let calendarsToFetch: [EKCalendar]?
        let calendarID = AppSettingsModel.shared.selectedSchoolCalendarID
        if !calendarID.isEmpty,
           let selectedCalendar = store.calendar(withIdentifier: calendarID)
        {
            calendarsToFetch = [selectedCalendar]
        } else {
            calendarsToFetch = nil
        }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendarsToFetch)
        let fetched = store.events(matching: predicate)

        await MainActor.run { [weak self] in
            self?.events = fetched
        }
    }

    func startObservingStoreChanges() {
        guard storeChangedObserver == nil else { return }

        storeChangedObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            guard self.authManager.isAuthorized else {
                self.authManager.logDeniedOnce(context: "storeChanged")
                return
            }
            Task { await self.refreshEventsForVisibleRange(reason: "storeChanged") }
        }

        isObservingStoreChanges = true
    }

    /// Get all available calendars from the event store
    func getAvailableCalendars() -> [EKCalendar] {
        guard isAuthorized else { return [] }
        return store.calendars(for: .event)
    }

    /// Reset calendar authorization (user must manually revoke in Settings app)
    func revokeAccess() {
        // Clear all cached data
        events = []
        lastRefreshAt = nil
        lastRefreshReason = nil
        isAuthorized = false

        // Stop observing changes
        if let observer = storeChangedObserver {
            NotificationCenter.default.removeObserver(observer)
            storeChangedObserver = nil
            isObservingStoreChanges = false
        }

        // Clear selected calendar
        AppSettingsModel.shared.selectedSchoolCalendarID = ""
    }
}
