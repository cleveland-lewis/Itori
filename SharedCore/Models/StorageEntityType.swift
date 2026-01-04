import Foundation

/// Represents all persisted entity types in Itori for Storage Center
/// Maps to STORAGE_DATA_INVENTORY.md
public enum StorageEntityType: String, CaseIterable, Identifiable, Codable {
    // MARK: - Academic
    case course = "Course"
    case semester = "Semester"
    case assignment = "Assignment"
    case grade = "Grade"
    
    // MARK: - Planning & Scheduling
    case plannerBlock = "Planner Block"
    case assignmentPlan = "Assignment Plan"
    case focusSession = "Focus Session"
    
    // MARK: - Testing & Practice
    case practiceTest = "Practice Test"
    case testBlueprint = "Test Blueprint"
    
    // MARK: - Content & Files
    case courseOutline = "Course Outline"
    case courseFile = "Course File"
    case attachment = "Attachment"
    
    // MARK: - Syllabus & Parsing
    case syllabus = "Syllabus"
    case parsedAssignment = "Parsed Assignment"
    
    // MARK: - Calendar & Events
    case calendarEvent = "Calendar Event"
    
    // MARK: - Timer & Focus
    case timerSession = "Timer Session"
    
    public var id: String { rawValue }
    
    /// Whether this entity type has a native title/name property
    public var hasNativeTitle: Bool {
        switch self {
        case .course, .assignment, .practiceTest, .testBlueprint,
             .courseOutline, .courseFile, .attachment, .parsedAssignment,
             .calendarEvent:
            return true
        case .semester, .grade, .plannerBlock, .assignmentPlan,
             .focusSession, .syllabus, .timerSession:
            return false
        }
    }
    
    /// Category for grouping in UI
    public var category: EntityCategory {
        switch self {
        case .course, .semester, .assignment, .grade:
            return .academic
        case .plannerBlock, .assignmentPlan, .focusSession:
            return .planning
        case .practiceTest, .testBlueprint:
            return .testing
        case .courseOutline, .courseFile, .attachment:
            return .content
        case .syllabus, .parsedAssignment:
            return .syllabus
        case .calendarEvent:
            return .calendar
        case .timerSession:
            return .timer
        }
    }
    
    /// User-facing type label for lists
    public var displayTypeName: String {
        return rawValue
    }
    
    /// SF Symbol icon for this entity type
    public var icon: String {
        switch self {
        case .course: return "book.closed"
        case .semester: return "calendar"
        case .assignment: return "doc.text"
        case .grade: return "chart.bar"
        case .plannerBlock: return "calendar.badge.clock"
        case .assignmentPlan: return "list.bullet.clipboard"
        case .focusSession: return "timer"
        case .practiceTest: return "doc.badge.gearshape"
        case .testBlueprint: return "doc.on.doc"
        case .courseOutline: return "list.bullet.indent"
        case .courseFile: return "doc"
        case .attachment: return "paperclip"
        case .syllabus: return "doc.richtext"
        case .parsedAssignment: return "doc.text.magnifyingglass"
        case .calendarEvent: return "calendar.badge.clock"
        case .timerSession: return "timer.square"
        }
    }
}

/// High-level categories for entity grouping
public enum EntityCategory: String, CaseIterable, Identifiable {
    case academic = "Academic"
    case planning = "Planning"
    case testing = "Testing"
    case content = "Content"
    case syllabus = "Syllabus"
    case calendar = "Calendar"
    case timer = "Timer"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .academic: return "graduationcap"
        case .planning: return "calendar.badge.clock"
        case .testing: return "checkmark.seal"
        case .content: return "doc.on.doc"
        case .syllabus: return "doc.richtext"
        case .calendar: return "calendar"
        case .timer: return "timer"
        }
    }
}

/// Protocol that all storage-listable entities must conform to
public protocol StorageListable: Identifiable {
    /// Human-readable display title (native or computed)
    var displayTitle: String { get }
    
    /// Entity type classification
    var entityType: StorageEntityType { get }
    
    /// Contextual description (course name, semester, etc.)
    var contextDescription: String? { get }
    
    /// Primary date for sorting and retention (created, due, modified)
    var primaryDate: Date { get }
    
    /// Optional status indicator (completed, archived, active)
    var statusDescription: String? { get }
    
    /// Search text combining all relevant fields
    var searchableText: String { get }
}

/// Default implementations for common patterns
public extension StorageListable {
    var statusDescription: String? { nil }
    
    var searchableText: String {
        var components = [displayTitle, entityType.rawValue]
        if let context = contextDescription {
            components.append(context)
        }
        return components.joined(separator: " ")
    }
}

/// Aggregated storage item for unified list view
public struct StorageListItem: Identifiable, Hashable {
    public let id: UUID
    public let displayTitle: String
    public let entityType: StorageEntityType
    public let contextDescription: String?
    public let primaryDate: Date
    public let statusDescription: String?
    
    /// Reference to original entity for edit/delete
    public let entityId: String
    public let entityStore: String // Store identifier for routing
    
    public init(
        id: UUID = UUID(),
        displayTitle: String,
        entityType: StorageEntityType,
        contextDescription: String? = nil,
        primaryDate: Date,
        statusDescription: String? = nil,
        entityId: String,
        entityStore: String
    ) {
        self.id = id
        self.displayTitle = displayTitle
        self.entityType = entityType
        self.contextDescription = contextDescription
        self.primaryDate = primaryDate
        self.statusDescription = statusDescription
        self.entityId = entityId
        self.entityStore = entityStore
    }
    
    /// Full text for search
    public var searchText: String {
        var components = [displayTitle, entityType.rawValue]
        if let context = contextDescription {
            components.append(context)
        }
        if let status = statusDescription {
            components.append(status)
        }
        return components.joined(separator: " ").lowercased()
    }
}
