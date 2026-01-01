//
//  MockFileWatcher.swift
//  RootsTests
//
//  Created for Phase 6.6: File System Watchers Testing
//

import Foundation
@testable import Roots

enum FileChangeType {
    case created
    case modified
    case deleted
    case renamed(oldName: String, newName: String)
}

struct FileChangeEvent {
    let path: URL
    let type: FileChangeType
    let timestamp: Date
}

class MockFileWatcher {
    var isWatching = false
    var watchedPaths: Set<URL> = []
    var changeHandler: ((FileChangeEvent) -> Void)?
    var recordedEvents: [FileChangeEvent] = []
    var shouldDelayEvents = false
    var eventDelay: TimeInterval = 0.1
    
    func startWatching(path: URL) {
        isWatching = true
        watchedPaths.insert(path)
    }
    
    func stopWatching(path: URL) {
        watchedPaths.remove(path)
        if watchedPaths.isEmpty {
            isWatching = false
        }
    }
    
    func stopAllWatching() {
        isWatching = false
        watchedPaths.removeAll()
    }
    
    func simulateFileChange(path: URL, type: FileChangeType) {
        let event = FileChangeEvent(path: path, type: type, timestamp: Date())
        recordedEvents.append(event)
        
        if shouldDelayEvents {
            DispatchQueue.main.asyncAfter(deadline: .now() + eventDelay) { [weak self] in
                self?.changeHandler?(event)
            }
        } else {
            changeHandler?(event)
        }
    }
    
    func simulateBatchChanges(_ changes: [(URL, FileChangeType)]) {
        for (path, type) in changes {
            simulateFileChange(path: path, type: type)
        }
    }
    
    func reset() {
        isWatching = false
        watchedPaths.removeAll()
        recordedEvents.removeAll()
        changeHandler = nil
        shouldDelayEvents = false
    }
}
