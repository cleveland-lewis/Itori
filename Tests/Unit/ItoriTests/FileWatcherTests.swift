//
//  FileWatcherTests.swift
//  ItoriTests
//
//  Phase 6.6: File System Watchers Testing
//

import XCTest
@testable import Itori

final class FileWatcherTests: XCTestCase {
    var mockWatcher: MockFileWatcher!
    var testURL: URL!
    
    override func setUp() {
        super.setUp()
        mockWatcher = MockFileWatcher()
        testURL = URL(fileURLWithPath: "/test/path/file.txt")
    }
    
    override func tearDown() {
        mockWatcher = nil
        testURL = nil
        super.tearDown()
    }
    
    // MARK: - Start/Stop Watching Tests
    
    func testStartWatching() {
        mockWatcher.startWatching(path: testURL)
        
        XCTAssertTrue(mockWatcher.isWatching)
        XCTAssertTrue(mockWatcher.watchedPaths.contains(testURL))
    }
    
    func testStopWatching() {
        mockWatcher.startWatching(path: testURL)
        mockWatcher.stopWatching(path: testURL)
        
        XCTAssertFalse(mockWatcher.isWatching)
        XCTAssertFalse(mockWatcher.watchedPaths.contains(testURL))
    }
    
    func testWatchMultiplePaths() {
        let url1 = URL(fileURLWithPath: "/test/file1.txt")
        let url2 = URL(fileURLWithPath: "/test/file2.txt")
        
        mockWatcher.startWatching(path: url1)
        mockWatcher.startWatching(path: url2)
        
        XCTAssertTrue(mockWatcher.isWatching)
        XCTAssertEqual(mockWatcher.watchedPaths.count, 2)
        XCTAssertTrue(mockWatcher.watchedPaths.contains(url1))
        XCTAssertTrue(mockWatcher.watchedPaths.contains(url2))
    }
    
    func testStopOnePathKeepsOthersWatching() {
        let url1 = URL(fileURLWithPath: "/test/file1.txt")
        let url2 = URL(fileURLWithPath: "/test/file2.txt")
        
        mockWatcher.startWatching(path: url1)
        mockWatcher.startWatching(path: url2)
        mockWatcher.stopWatching(path: url1)
        
        XCTAssertTrue(mockWatcher.isWatching)
        XCTAssertTrue(mockWatcher.watchedPaths.contains(url2))
        XCTAssertFalse(mockWatcher.watchedPaths.contains(url1))
    }
    
    func testStopAllWatching() {
        let url1 = URL(fileURLWithPath: "/test/file1.txt")
        let url2 = URL(fileURLWithPath: "/test/file2.txt")
        
        mockWatcher.startWatching(path: url1)
        mockWatcher.startWatching(path: url2)
        mockWatcher.stopAllWatching()
        
        XCTAssertFalse(mockWatcher.isWatching)
        XCTAssertTrue(mockWatcher.watchedPaths.isEmpty)
    }
    
    // MARK: - File Change Detection Tests
    
    func testFileCreation() {
        let expectation = expectation(description: "File created")
        
        mockWatcher.changeHandler = { event in
            if case .created = event.type {
                XCTAssertEqual(event.path, self.testURL)
                expectation.fulfill()
            }
        }
        
        mockWatcher.startWatching(path: testURL)
        mockWatcher.simulateFileChange(path: testURL, type: .created)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFileModification() {
        let expectation = expectation(description: "File modified")
        
        mockWatcher.changeHandler = { event in
            if case .modified = event.type {
                expectation.fulfill()
            }
        }
        
        mockWatcher.startWatching(path: testURL)
        mockWatcher.simulateFileChange(path: testURL, type: .modified)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFileDeletion() {
        let expectation = expectation(description: "File deleted")
        
        mockWatcher.changeHandler = { event in
            if case .deleted = event.type {
                expectation.fulfill()
            }
        }
        
        mockWatcher.startWatching(path: testURL)
        mockWatcher.simulateFileChange(path: testURL, type: .deleted)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFileRename() {
        let expectation = expectation(description: "File renamed")
        let oldName = "old.txt"
        let newName = "new.txt"
        
        mockWatcher.changeHandler = { event in
            if case .renamed(let old, let new) = event.type {
                XCTAssertEqual(old, oldName)
                XCTAssertEqual(new, newName)
                expectation.fulfill()
            }
        }
        
        mockWatcher.startWatching(path: testURL)
        mockWatcher.simulateFileChange(path: testURL, type: .renamed(oldName: oldName, newName: newName))
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Batch Changes Tests
    
    func testBatchChanges() {
        let url1 = URL(fileURLWithPath: "/test/file1.txt")
        let url2 = URL(fileURLWithPath: "/test/file2.txt")
        let url3 = URL(fileURLWithPath: "/test/file3.txt")
        
        let changes: [(URL, FileChangeType)] = [
            (url1, .created),
            (url2, .modified),
            (url3, .deleted)
        ]
        
        mockWatcher.startWatching(path: URL(fileURLWithPath: "/test"))
        mockWatcher.simulateBatchChanges(changes)
        
        XCTAssertEqual(mockWatcher.recordedEvents.count, 3)
    }
    
    // MARK: - Event Recording Tests
    
    func testEventRecording() {
        mockWatcher.startWatching(path: testURL)
        mockWatcher.simulateFileChange(path: testURL, type: .created)
        mockWatcher.simulateFileChange(path: testURL, type: .modified)
        mockWatcher.simulateFileChange(path: testURL, type: .deleted)
        
        XCTAssertEqual(mockWatcher.recordedEvents.count, 3)
    }
    
    func testEventTimestamps() {
        mockWatcher.startWatching(path: testURL)
        let beforeTime = Date()
        mockWatcher.simulateFileChange(path: testURL, type: .created)
        let afterTime = Date()
        
        XCTAssertEqual(mockWatcher.recordedEvents.count, 1)
        let event = mockWatcher.recordedEvents[0]
        XCTAssertTrue(event.timestamp >= beforeTime)
        XCTAssertTrue(event.timestamp <= afterTime)
    }
    
    // MARK: - Delayed Events Tests
    
    func testDelayedEvents() {
        mockWatcher.shouldDelayEvents = true
        mockWatcher.eventDelay = 0.2
        
        let expectation = expectation(description: "Delayed event")
        
        mockWatcher.changeHandler = { _ in
            expectation.fulfill()
        }
        
        mockWatcher.startWatching(path: testURL)
        mockWatcher.simulateFileChange(path: testURL, type: .created)
        
        wait(for: [expectation], timeout: 0.5)
    }
    
    // MARK: - Reset Tests
    
    func testReset() {
        mockWatcher.startWatching(path: testURL)
        mockWatcher.simulateFileChange(path: testURL, type: .created)
        mockWatcher.shouldDelayEvents = true
        
        mockWatcher.reset()
        
        XCTAssertFalse(mockWatcher.isWatching)
        XCTAssertTrue(mockWatcher.watchedPaths.isEmpty)
        XCTAssertTrue(mockWatcher.recordedEvents.isEmpty)
        XCTAssertNil(mockWatcher.changeHandler)
        XCTAssertFalse(mockWatcher.shouldDelayEvents)
    }
}
