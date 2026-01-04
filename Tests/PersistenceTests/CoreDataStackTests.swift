//
//  CoreDataStackTests.swift
//  ItoriTests
//
//  Tests for Core Data + CloudKit persistence layer
//

import XCTest
import CoreData
@testable import Itori

final class CoreDataStackTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        // Create in-memory store for testing
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.viewContext
    }
    
    override func tearDown() {
        context = nil
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Basic Tests
    
    func testPersistenceControllerInitialization() {
        XCTAssertNotNil(persistenceController)
        XCTAssertNotNil(context)
        XCTAssertEqual(context.automaticallyMergesChangesFromParent, true)
    }
    
    func testViewContextMergePolicy() {
        XCTAssertTrue(context.mergePolicy is NSMergeByPropertyObjectTrumpMergePolicy)
    }
    
    func testBackgroundContextCreation() {
        let backgroundContext = persistenceController.newBackgroundContext()
        XCTAssertNotNil(backgroundContext)
        XCTAssertTrue(backgroundContext.mergePolicy is NSMergeByPropertyObjectTrumpMergePolicy)
        XCTAssertNotEqual(backgroundContext, context)
    }
    
    // MARK: - TimerSession Tests
    
    func testCreateTimerSession() throws {
        let session = NSEntityDescription.insertNewObject(forEntityName: "TimerSession", into: context)
        session.setValue(UUID(), forKey: "id")
        session.setValue(Date(), forKey: "createdAt")
        session.setValue(Date(), forKey: "updatedAt")
        session.setValue(1800.0, forKey: "durationSeconds")
        session.setValue("focus", forKey: "mode")
        session.setValue(Date(), forKey: "startedAt")
        session.setValue(Date().addingTimeInterval(1800), forKey: "endedAt")
        
        try context.save()
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "TimerSession")
        let results = try context.fetch(fetchRequest)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.value(forKey: "durationSeconds") as? Double, 1800)
        XCTAssertEqual(results.first?.value(forKey: "mode") as? String, "focus")
    }
    
    func testTimerSessionTimestamps() throws {
        let beforeCreate = Date()
        
        let session = NSEntityDescription.insertNewObject(forEntityName: "TimerSession", into: context)
        let createdAt = Date()
        session.setValue(UUID(), forKey: "id")
        session.setValue(createdAt, forKey: "createdAt")
        session.setValue(createdAt, forKey: "updatedAt")
        session.setValue(600.0, forKey: "durationSeconds")
        
        try context.save()
        
        let afterCreate = Date()
        
        XCTAssertNotNil(session.value(forKey: "createdAt"))
        XCTAssertNotNil(session.value(forKey: "updatedAt"))
        
        let savedCreatedAt = session.value(forKey: "createdAt") as! Date
        XCTAssertGreaterThanOrEqual(savedCreatedAt, beforeCreate)
        XCTAssertLessThanOrEqual(savedCreatedAt, afterCreate)
    }
    
    // MARK: - Performance Tests
    
    func testBulkInsertPerformance() throws {
        measure {
            let context = persistenceController.newBackgroundContext()
            
            for i in 0..<100 {
                let session = NSEntityDescription.insertNewObject(forEntityName: "TimerSession", into: context)
                session.setValue(UUID(), forKey: "id")
                session.setValue(Date(), forKey: "createdAt")
                session.setValue(Date(), forKey: "updatedAt")
                session.setValue(Double(i * 60), forKey: "durationSeconds")
                session.setValue("focus", forKey: "mode")
            }
            
            try? context.save()
        }
    }
}
