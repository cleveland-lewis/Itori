import Foundation

enum FlashcardDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy, medium, hard
    var id: String { rawValue }
}

struct Flashcard: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var frontText: String
    var backText: String
    var difficulty: FlashcardDifficulty = .medium
    var lastReviewed: Date? = nil
    var interval: Int = 0              // days
    var easeFactor: Double = 2.5
    var repetition: Int = 0
    var dueDate: Date = Date()

    init(id: UUID = UUID(),
         frontText: String,
         backText: String,
         difficulty: FlashcardDifficulty = .medium,
         lastReviewed: Date? = nil,
         interval: Int = 0,
         easeFactor: Double = 2.5,
         repetition: Int = 0,
         dueDate: Date = Date()) {
        self.id = id
        self.frontText = frontText
        self.backText = backText
        self.difficulty = difficulty
        self.lastReviewed = lastReviewed
        self.interval = interval
        self.easeFactor = easeFactor
        self.repetition = repetition
        self.dueDate = dueDate
    }

    /// Considered mastered if interval is beyond three weeks.
    var isMastered: Bool { interval > 21 }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        frontText = try container.decode(String.self, forKey: .frontText)
        backText = try container.decode(String.self, forKey: .backText)
        difficulty = try container.decodeIfPresent(FlashcardDifficulty.self, forKey: .difficulty) ?? .medium
        lastReviewed = try container.decodeIfPresent(Date.self, forKey: .lastReviewed)
        interval = try container.decodeIfPresent(Int.self, forKey: .interval) ?? 0
        easeFactor = try container.decodeIfPresent(Double.self, forKey: .easeFactor) ?? 2.5
        repetition = try container.decodeIfPresent(Int.self, forKey: .repetition) ?? 0
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate) ?? Date()
    }
}

struct FlashcardDeck: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var courseID: UUID?
    var createdDate: Date = Date()
    var cards: [Flashcard] = []
}
