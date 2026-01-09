//
//  DragDropTypes.swift
//  Itori
//
//  Drag & drop type definitions and UTIs
//

import CoreTransferable
import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Custom UTIs for Itori entities
extension UTType {
    /// Assignment drag type: com.itori.assignment
    static let itoriAssignment = UTType(exportedAs: "com.itori.assignment")

    /// Course drag type: com.itori.course
    static let itoriCourse = UTType(exportedAs: "com.itori.course")

    /// Planner session drag type: com.itori.session
    static let itoriSession = UTType(exportedAs: "com.itori.session")

    /// Calendar event drag type: com.itori.calendar.event
    static let itoriCalendarEvent = UTType(exportedAs: "com.itori.calendar.event")
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
        code.isEmpty ? title : "\(code) - \(title)"
    }
}

@MainActor
@preconcurrency extension TransferableAssignment: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .itoriAssignment)
        DataRepresentation(exportedContentType: .plainText) { payload in
            Data(payload.plainTextRepresentation.utf8)
        }
    }
}

@MainActor
@preconcurrency extension TransferableCourse: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .itoriCourse)
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
