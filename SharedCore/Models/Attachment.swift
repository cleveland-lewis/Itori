import Foundation

public enum AttachmentTag: String, Codable {
    case syllabus, lecture, other
}

public extension AttachmentTag {
    var icon: String {
        switch self {
        case .syllabus: "doc.text"
        case .lecture: "book"
        case .other: "paperclip"
        }
    }
}

public struct Attachment: Codable, Equatable, Hashable, Identifiable {
    public let id: UUID
    public let name: String?
    public let localURL: URL?
    public let dateAdded: Date?
    public let tag: AttachmentTag?
    public let moduleNumber: Int?

    public init(
        id: UUID = UUID(),
        name: String? = nil,
        localURL: URL? = nil,
        dateAdded: Date? = nil,
        tag: AttachmentTag? = nil,
        moduleNumber: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.localURL = localURL
        self.dateAdded = dateAdded
        self.tag = tag
        self.moduleNumber = moduleNumber
    }
}
