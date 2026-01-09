import EventKit
import Foundation

protocol EventStorable {
    func requestEventStoreAccess() async throws -> Bool
    func fetchEvents(matching predicate: NSPredicate) -> [EKEvent]
}

extension EKEventStore: EventStorable {
    func requestEventStoreAccess() async throws -> Bool {
        if #available(macOS 14.0, iOS 17.0, *) {
            try await requestFullAccessToEvents()
        } else {
            try await requestAccess(to: .event)
        }
    }

    func fetchEvents(matching predicate: NSPredicate) -> [EKEvent] {
        events(matching: predicate)
    }
}
