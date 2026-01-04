//
//  AttachmentTests.swift
//  ItoriTests
//
//  Tests for Attachment model
//

import XCTest
@testable import Roots

@MainActor
final class AttachmentTests: BaseTestCase {
    
    // MARK: - AttachmentTag Tests
    
    func testAttachmentTagAllCases() {
        XCTAssertEqual(AttachmentTag.syllabus.rawValue, "syllabus")
        XCTAssertEqual(AttachmentTag.lecture.rawValue, "lecture")
        XCTAssertEqual(AttachmentTag.other.rawValue, "other")
    }
    
    func testAttachmentTagIcons() {
        XCTAssertEqual(AttachmentTag.syllabus.icon, "doc.text")
        XCTAssertEqual(AttachmentTag.lecture.icon, "book")
        XCTAssertEqual(AttachmentTag.other.icon, "paperclip")
    }
    
    func testAttachmentTagCodable() throws {
        let tag = AttachmentTag.syllabus
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(tag)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AttachmentTag.self, from: data)
        
        XCTAssertEqual(decoded, tag)
    }
    
    // MARK: - Attachment Tests
    
    func testAttachmentInitialization() {
        let url = URL(fileURLWithPath: "/test/file.pdf")
        let date = Date()
        
        let attachment = Attachment(
            id: UUID(),
            name: "Test File",
            localURL: url,
            dateAdded: date,
            tag: .syllabus,
            moduleNumber: 3
        )
        
        XCTAssertEqual(attachment.name, "Test File")
        XCTAssertEqual(attachment.localURL, url)
        XCTAssertEqual(attachment.dateAdded, date)
        XCTAssertEqual(attachment.tag, .syllabus)
        XCTAssertEqual(attachment.moduleNumber, 3)
    }
    
    func testAttachmentDefaultInitialization() {
        let attachment = Attachment()
        
        XCTAssertNotNil(attachment.id)
        XCTAssertNil(attachment.name)
        XCTAssertNil(attachment.localURL)
        XCTAssertNil(attachment.dateAdded)
        XCTAssertNil(attachment.tag)
        XCTAssertNil(attachment.moduleNumber)
    }
    
    func testAttachmentEquatable() {
        let id = UUID()
        let url = URL(fileURLWithPath: "/test/file.pdf")
        
        let attachment1 = Attachment(
            id: id,
            name: "Test",
            localURL: url,
            dateAdded: Date(),
            tag: .lecture,
            moduleNumber: 1
        )
        
        let attachment2 = Attachment(
            id: id,
            name: "Test",
            localURL: url,
            dateAdded: Date(),
            tag: .lecture,
            moduleNumber: 1
        )
        
        XCTAssertEqual(attachment1, attachment2)
    }
    
    func testAttachmentHashable() {
        let id = UUID()
        let attachment = Attachment(id: id, name: "Test")
        
        var set = Set<Attachment>()
        set.insert(attachment)
        
        XCTAssertTrue(set.contains(attachment))
        XCTAssertEqual(set.count, 1)
    }
    
    func testAttachmentCodable() throws {
        let url = URL(fileURLWithPath: "/test/file.pdf")
        let attachment = Attachment(
            id: UUID(),
            name: "Syllabus",
            localURL: url,
            dateAdded: Date(),
            tag: .syllabus,
            moduleNumber: 1
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(attachment)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Attachment.self, from: data)
        
        XCTAssertEqual(decoded.id, attachment.id)
        XCTAssertEqual(decoded.name, attachment.name)
        XCTAssertEqual(decoded.localURL, attachment.localURL)
        XCTAssertEqual(decoded.tag, attachment.tag)
        XCTAssertEqual(decoded.moduleNumber, attachment.moduleNumber)
    }
    
    // MARK: - Edge Cases
    
    func testAttachmentWithEmptyName() {
        let attachment = Attachment(name: "")
        
        XCTAssertEqual(attachment.name, "")
    }
    
    func testAttachmentWithInvalidURL() {
        // Test that URL can be any valid file URL
        let url = URL(fileURLWithPath: "/nonexistent/path/file.pdf")
        let attachment = Attachment(localURL: url)
        
        XCTAssertEqual(attachment.localURL, url)
    }
    
    func testAttachmentWithZeroModuleNumber() {
        let attachment = Attachment(moduleNumber: 0)
        
        XCTAssertEqual(attachment.moduleNumber, 0)
    }
    
    func testAttachmentWithNegativeModuleNumber() {
        let attachment = Attachment(moduleNumber: -1)
        
        XCTAssertEqual(attachment.moduleNumber, -1)
    }
    
    func testAttachmentWithLargeModuleNumber() {
        let attachment = Attachment(moduleNumber: 999)
        
        XCTAssertEqual(attachment.moduleNumber, 999)
    }
    
    func testAttachmentWithRemoteURL() {
        let url = URL(string: "https://example.com/file.pdf")!
        let attachment = Attachment(localURL: url)
        
        XCTAssertEqual(attachment.localURL, url)
    }
    
    func testAttachmentIdentifiable() {
        let attachment1 = Attachment()
        let attachment2 = Attachment()
        
        XCTAssertNotEqual(attachment1.id, attachment2.id)
    }
    
    // MARK: - Collection Tests
    
    func testAttachmentInArray() {
        let attachments = [
            Attachment(name: "File 1", tag: .syllabus),
            Attachment(name: "File 2", tag: .lecture),
            Attachment(name: "File 3", tag: .other)
        ]
        
        XCTAssertEqual(attachments.count, 3)
        XCTAssertEqual(attachments[0].tag, .syllabus)
        XCTAssertEqual(attachments[1].tag, .lecture)
        XCTAssertEqual(attachments[2].tag, .other)
    }
    
    func testAttachmentFiltering() {
        let attachments = [
            Attachment(name: "Syllabus 1", tag: .syllabus),
            Attachment(name: "Lecture 1", tag: .lecture),
            Attachment(name: "Syllabus 2", tag: .syllabus)
        ]
        
        let syllabi = attachments.filter { $0.tag == .syllabus }
        
        XCTAssertEqual(syllabi.count, 2)
    }
}
