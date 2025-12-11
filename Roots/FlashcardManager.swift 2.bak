import Foundation
import SwiftUI
import Combine

@MainActor
final class FlashcardManager: ObservableObject {
    static let shared = FlashcardManager()

    @Published private(set) var decks: [FlashcardDeck] = []

    private var storageURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("flashcards.json")
    }

    private init() {
        load()
    }

    func createDeck(title: String, courseID: UUID? = nil) -> FlashcardDeck {
        let deck = FlashcardDeck(title: title, courseID: courseID)
        decks.append(deck)
        save()
        return deck
    }

    func addCard(to deckId: UUID, front: String, back: String, difficulty: FlashcardDifficulty = .medium) {
        guard let idx = decks.firstIndex(where: { $0.id == deckId }) else { return }
        var d = decks[idx]
        let card = Flashcard(frontText: front, backText: back, difficulty: difficulty)
        d.cards.append(card)
        decks[idx] = d
        save()
    }

    func updateDeck(_ deck: FlashcardDeck) {
        guard let idx = decks.firstIndex(where: { $0.id == deck.id }) else { return }
        decks[idx] = deck
        save()
    }

    func deleteDeck(_ deckId: UUID) {
        decks.removeAll { $0.id == deckId }
        save()
    }

    func exportToAnki(deck: FlashcardDeck) -> String {
        // CSV with Front,Back per line
        let lines = deck.cards.map { card in
            let front = card.frontText.replacingOccurrences(of: "\n", with: " ")
            let back = card.backText.replacingOccurrences(of: "\n", with: " ")
            let quotedFront = "\"\(front.replacingOccurrences(of: "\"", with: "\"\""))\""
            let quotedBack = "\"\(back.replacingOccurrences(of: "\"", with: "\"\""))\""
            return "\(quotedFront),\(quotedBack)"
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Persistence
    private func save() {
        do {
            let data = try JSONEncoder().encode(decks)
            try data.write(to: storageURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("[FlashcardManager] Failed to save flashcards: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            decks = []
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            decks = try JSONDecoder().decode([FlashcardDeck].self, from: data)
        } catch {
            print("[FlashcardManager] Failed to load flashcards: \(error)")
            decks = []
        }
    }
}
