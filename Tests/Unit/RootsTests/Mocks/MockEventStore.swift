//
//  MockEventStore.swift
//  RootsTests
//
//  Created for Phase 6.2: EventKit Integration Testing
//

import Foundation
import EventKit
@testable import Roots

enum MockEventStoreError: Error {
    case accessDenied
    case eventNotFound
    case saveFailed
}

class MockEventStore {
    var hasAccess = true
    var events: [EKEvent] = []
    var calendars: [EKCalendar] = []
    var requestAccessCallCount = 0
    var saveCallCount = 0
    var removeCallCount = 0
    var shouldFailSave = false
    
    func requestAccess() async -> Bool {
        requestAccessCallCount += 1
        return hasAccess
    }
    
    func fetchEvents(from startDate: Date, to endDate: Date, calendars: [EKCalendar]? = nil) -> [EKEvent] {
        let filteredEvents = events.filter { event in
            guard let eventStart = event.startDate, let eventEnd = event.endDate else { return false }
            let overlaps = eventStart < endDate && eventEnd > startDate
            
            if let calendars = calendars {
                return overlaps && calendars.contains(event.calendar)
            }
            return overlaps
        }
        return filteredEvents
    }
    
    func save(event: EKEvent) throws {
        saveCallCount += 1
        
        if !hasAccess {
            throw MockEventStoreError.accessDenied
        }
        
        if shouldFailSave {
            throw MockEventStoreError.saveFailed
        }
        
        // Check if updating existing event
        if let index = events.firstIndex(where: { $0.eventIdentifier == event.eventIdentifier }) {
            events[index] = event
        } else {
            events.append(event)
        }
    }
    
    func remove(event: EKEvent) throws {
        removeCallCount += 1
        
        if !hasAccess {
            throw MockEventStoreError.accessDenied
        }
        
        guard let index = events.firstIndex(where: { $0.eventIdentifier == event.eventIdentifier }) else {
            throw MockEventStoreError.eventNotFound
        }
        
        events.remove(at: index)
    }
    
    func reset() {
        events.removeAll()
        calendars.removeAll()
        requestAccessCallCount = 0
        saveCallCount = 0
        removeCallCount = 0
        hasAccess = true
        shouldFailSave = false
    }
}
