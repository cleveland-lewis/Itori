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
}

struct FlashcardDeck: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var courseID: UUID?
    var createdDate: Date = Date()
    var cards: [Flashcard] = []
}
