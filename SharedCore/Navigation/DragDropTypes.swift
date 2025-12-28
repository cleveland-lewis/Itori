//
//  DragDropTypes.swift
//  Roots
//
//  Drag & drop type definitions and UTIs
//

import Foundation
import UniformTypeIdentifiers
import CoreTransferable
import SwiftUI

/// Custom UTIs for Roots entities
extension UTType {
    /// Assignment drag type: com.roots.assignment
    static let rootsAssignment = UTType(exportedAs: "com.roots.assignment")
    
    /// Course drag type: com.roots.course  
    static let rootsCourse = UTType(exportedAs: "com.roots.course")
    
    /// Planner session drag type: com.roots.session
    static let rootsSession = UTType(exportedAs: "com.roots.session")

    /// Calendar event drag type: com.roots.calendar.event
    static let rootsCalendarEvent = UTType(exportedAs: "com.roots.calendar.event")
}

/// Transferable assignment representation for drag & drop
nonisolated struct TransferableAssignment: Codable, Sendable {
    let id: String
    let title: String
    let courseId: String?
    let dueDate: Date?
    let estimatedMinutes: Int
    
    init(from task: AppTask) {
        self.id = task.id.uuidString
        self.title = task.title
        self.courseId = task.courseId?.uuidString
        self.dueDate = task.due
        self.estimatedMinutes = task.estimatedMinutes
    }
    
    /// Export as plain text for cross-app compatibility
    var plainTextRepresentation: String {
        var text = title
        if let due = dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            text += "\nDue: \(formatter.string(from: due))"
        }
        text += "\nEstimated time: \(estimatedMinutes) minutes"
        return text
    }
}

    /// Transferable course representation for drag & drop
nonisolated struct TransferableCourse: Codable, Sendable {
    let id: String
    let title: String
    let code: String
    let semesterId: String?
    
    /// Export as plain text
    var plainTextRepresentation: String {
        return code.isEmpty ? title : "\(code) - \(title)"
    }
}

extension TransferableAssignment: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .rootsAssignment)
        DataRepresentation(exportedContentType: .plainText) { payload in
            Data(payload.plainTextRepresentation.utf8)
        }
    }
}

extension TransferableCourse: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .rootsCourse)
        DataRepresentation(exportedContentType: .plainText) { payload in
            Data(payload.plainTextRepresentation.utf8)
        }
    }
}

/// Drop payload types for drag operations
enum DropPayload {
    case assignment(id: UUID)
    case course(id: UUID)
    case text(String)
}
