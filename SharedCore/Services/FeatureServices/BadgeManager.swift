import Foundation
import UserNotifications
import Combine
import EventKit

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// MARK: - Badge Source

/// Defines what the app icon badge count represents
public enum BadgeSource: String, Codable, CaseIterable, Identifiable {
    case off = "off"
    case upcomingAssignments = "upcoming_assignments"
    case eventsToday = "events_today"
    case eventsThisWeek = "events_this_week"
    case assignmentsThisWeek = "assignments_this_week"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .off:
            return "Off".localized
        case .upcomingAssignments:
            return "Upcoming Assignments (24h)".localized
        case .eventsToday:
            return "Events Today".localized
        case .eventsThisWeek:
            return "Events This Week".localized
        case .assignmentsThisWeek:
            return "Assignments This Week".localized
        }
    }
    
    public var description: String {
        switch self {
        case .off:
            return "No badge count".localized
        case .upcomingAssignments:
            return "Count assignments due in the next 24 hours".localized
        case .eventsToday:
            return "Count events scheduled for today".localized
        case .eventsThisWeek:
            return "Count events scheduled this week".localized
        case .assignmentsThisWeek:
            return "Count assignments due this week".localized
        }
    }
}

// MARK: - Badge Manager

/// Manages app icon badge count based on user-selected source
@MainActor
public final class BadgeManager: ObservableObject {
    public static let shared = BadgeManager()
    
    @Published public var badgeSource: BadgeSource {
        didSet {
            saveBadgeSource()
            updateBadge()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private let updateCoalesceInterval: TimeInterval = 2.0
    private var updateWorkItem: DispatchWorkItem?
    
    // Constants
    private let upcomingWindow: TimeInterval = 24 * 60 * 60 // 24 hours
    
    private init() {
        // Load saved preference
        if let savedRaw = UserDefaults.standard.string(forKey: "badgeSource"),
           let saved = BadgeSource(rawValue: savedRaw) {
            self.badgeSource = saved
        } else {
            self.badgeSource = .off
        }
        
        setupObservers()
    }
    
    private func setupObservers() {
        // Update badge when assignments change
        NotificationCenter.default.publisher(for: .assignmentsDidChange)
            .sink { [weak self] _ in
                self?.scheduleUpdate()
            }
            .store(in: &cancellables)
        
        // Update badge when events change
        NotificationCenter.default.publisher(for: .eventsDidChange)
            .sink { [weak self] _ in
                self?.scheduleUpdate()
            }
            .store(in: &cancellables)
        
        // Update badge at day/week boundaries
        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .sink { [weak self] _ in
                self?.updateBadge()
            }
            .store(in: &cancellables)
        
        // Update badge when app becomes active
        #if os(macOS)
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.updateBadge()
            }
            .store(in: &cancellables)
        #elseif os(iOS)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.updateBadge()
            }
            .store(in: &cancellables)
        #endif
    }
    
    /// Schedule a coalesced badge update to avoid spamming
    private func scheduleUpdate() {
        updateWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.updateBadge()
        }
        updateWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + updateCoalesceInterval, execute: workItem)
    }
    
    /// Update the app icon badge immediately
    public func updateBadge() {
        let count = calculateBadgeCount()
        setBadgeCount(count)
    }
    
    private func calculateBadgeCount() -> Int {
        switch badgeSource {
        case .off:
            return 0
        case .upcomingAssignments:
            return countUpcomingAssignments()
        case .eventsToday:
            return countEventsToday()
        case .eventsThisWeek:
            return countEventsThisWeek()
        case .assignmentsThisWeek:
            return countAssignmentsThisWeek()
        }
    }
    
    private func countUpcomingAssignments() -> Int {
        let now = Date()
        let windowEnd = now.addingTimeInterval(upcomingWindow)
        
        let store = AssignmentsStore.shared
        
        return store.tasks.filter { task in
            guard !task.isCompleted, let due = task.due else { return false }
            return due >= now && due <= windowEnd
        }.count
    }
    
    private func countEventsToday() -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        let deviceCalendar = DeviceCalendarManager.shared
        
        return deviceCalendar.events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: now)
        }.count
    }
    
    private func countEventsThisWeek() -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return 0
        }
        
        let deviceCalendar = DeviceCalendarManager.shared
        
        return deviceCalendar.events.filter { event in
            event.startDate >= weekStart && event.startDate < weekEnd
        }.count
    }
    
    private func countAssignmentsThisWeek() -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return 0
        }
        
        let store = AssignmentsStore.shared
        
        return store.tasks.filter { task in
            guard !task.isCompleted, let due = task.due else { return false }
            return due >= weekStart && due < weekEnd
        }.count
    }
    
    private func setBadgeCount(_ count: Int) {
        #if os(macOS)
        if count > 0 {
            NSApplication.shared.dockTile.badgeLabel = "\(count)"
        } else {
            NSApplication.shared.dockTile.badgeLabel = nil
        }
        #elseif os(iOS)
        UNUserNotificationCenter.current().setBadgeCount(count) { error in
            if let error {
                print("Failed to set badge count: \(error.localizedDescription)")
            }
        }
        #endif
    }
    
    private func saveBadgeSource() {
        UserDefaults.standard.set(badgeSource.rawValue, forKey: "badgeSource")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let assignmentsDidChange = Notification.Name("app.assignmentsDidChange")
    static let eventsDidChange = Notification.Name("app.eventsDidChange")
}
