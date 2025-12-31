//
//  FlashcardManagerTests.swift
//  RootsTests
//
//  Tests for FlashcardManager - Flashcard deck management
//

import XCTest
@testable import Roots

@MainActor
final class FlashcardManagerTests: BaseTestCase {
    
    var manager: FlashcardManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        manager = FlashcardManager.shared
        // Clear decks for testing
        manager.decks.forEach { manager.deleteDeck($0.id) }
    }
    
    override func tearDownWithError() throws {
        // Clean up
        manager.decks.forEach { manager.deleteDeck($0.id) }
        manager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testFlashcardManagerSharedInstance() {
        XCTAssertNotNil(FlashcardManager.shared)
    }
    
    func testFlashcardManagerInitialState() {
        // After cleanup, should be empty
        XCTAssertEqual(manager.decks.count, 0)
    }
    
    // MARK: - Deck Creation Tests
    
    func testCreateDeck() {
        let deck = manager.createDeck(title: "Spanish Vocab")
        
        XCTAssertEqual(manager.decks.count, 1)
        XCTAssertEqual(deck.title, "Spanish Vocab")
        XCTAssertNil(deck.courseID)
    }
    
    func testCreateDeckWithCourse() {
        let courseId = UUID()
        let deck = manager.createDeck(title: "Math Formulas", courseID: courseId)
        
        XCTAssertEqual(manager.decks.count, 1)
        XCTAssertEqual(deck.title, "Math Formulas")
        XCTAssertEqual(deck.courseID, courseId)
    }
    
    func testCreateMultipleDecks() {
        _ = manager.createDeck(title: "Deck 1")
        _ = manager.createDeck(title: "Deck 2")
        _ = manager.createDeck(title: "Deck 3")
        
        XCTAssertEqual(manager.decks.count, 3)
    }
    
    // MARK: - Card Addition Tests
    
    func testAddCardToDeck() {
        let deck = manager.createDeck(title: "Test Deck")
        
        manager.addCard(to: deck.id, front: "Front", back: "Back")
        
        let updatedDeck = manager.deck(withId: deck.id)
        XCTAssertEqual(updatedDeck?.cards.count, 1)
        XCTAssertEqual(updatedDeck?.cards.first?.frontText, "Front")
        XCTAssertEqual(updatedDeck?.cards.first?.backText, "Back")
    }
    
    func testAddCardWithDifficulty() {
        let deck = manager.createDeck(title: "Test Deck")
        
        manager.addCard(to: deck.id, front: "Hard Question", back: "Complex Answer", difficulty: .hard)
        
        let updatedDeck = manager.deck(withId: deck.id)
        XCTAssertEqual(updatedDeck?.cards.first?.difficulty, .hard)
    }
    
    func testAddMultipleCards() {
        let deck = manager.createDeck(title: "Test Deck")
        
        manager.addCard(to: deck.id, front: "Q1", back: "A1")
        manager.addCard(to: deck.id, front: "Q2", back: "A2")
        manager.addCard(to: deck.id, front: "Q3", back: "A3")
        
        let updatedDeck = manager.deck(withId: deck.id)
        XCTAssertEqual(updatedDeck?.cards.count, 3)
    }
    
    func testAddCardToNonexistentDeck() {
        let fakeId = UUID()
        
        manager.addCard(to: fakeId, front: "Front", back: "Back")
        
        // Should not crash, just do nothing
        XCTAssertTrue(true)
    }
    
    // MARK: - Deck Retrieval Tests
    
    func testDeckWithId() {
        let deck = manager.createDeck(title: "Find Me")
        
        let found = manager.deck(withId: deck.id)
        
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, deck.id)
        XCTAssertEqual(found?.title, "Find Me")
    }
    
    func testDeckWithIdNotFound() {
        let fakeId = UUID()
        
        let found = manager.deck(withId: fakeId)
        
        XCTAssertNil(found)
    }
    
    // MARK: - Deck Update Tests
    
    func testUpdateDeck() {
        var deck = manager.createDeck(title: "Original Title")
        deck.title = "Updated Title"
        
        manager.updateDeck(deck)
        
        let updated = manager.deck(withId: deck.id)
        XCTAssertEqual(updated?.title, "Updated Title")
    }
    
    // MARK: - Due Cards Tests
    
    func testDueCardsEmpty() {
        let deck = manager.createDeck(title: "Test Deck")
        
        let due = manager.dueCards(for: deck.id)
        
        XCTAssertEqual(due.count, 0)
    }
    
    func testDueCardsWithPastDueDates() {
        let deck = manager.createDeck(title: "Test Deck")
        let past = Date().addingTimeInterval(-86400) // Yesterday
        
        manager.addCard(to: deck.id, front: "Q1", back: "A1")
        
        // Manually set due date (in real code, this is done by review logic)
        if var updatedDeck = manager.deck(withId: deck.id) {
            updatedDeck.cards[0].dueDate = past
            manager.updateDeck(updatedDeck)
        }
        
        let due = manager.dueCards(for: deck.id)
        
        XCTAssertGreaterThanOrEqual(due.count, 1)
    }
    
    // MARK: - Deck Deletion Tests
    
    func testDeleteDeck() {
        let deck = manager.createDeck(title: "Delete Me")
        XCTAssertEqual(manager.decks.count, 1)
        
        manager.deleteDeck(deck.id)
        
        XCTAssertEqual(manager.decks.count, 0)
    }
    
    func testDeleteNonexistentDeck() {
        let fakeId = UUID()
        
        manager.deleteDeck(fakeId)
        
        // Should not crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Anki Export Tests
    
    func testExportToAnkiEmpty() {
        let deck = manager.createDeck(title: "Empty Deck")
        
        let csv = manager.exportToAnki(deck: deck)
        
        XCTAssertEqual(csv, "")
    }
    
    func testExportToAnkiSingleCard() {
        let deck = manager.createDeck(title: "Export Test")
        manager.addCard(to: deck.id, front: "Front", back: "Back")
        
        let updatedDeck = manager.deck(withId: deck.id)!
        let csv = manager.exportToAnki(deck: updatedDeck)
        
        XCTAssertTrue(csv.contains("Front"))
        XCTAssertTrue(csv.contains("Back"))
    }
    
    func testExportToAnkiMultipleCards() {
        let deck = manager.createDeck(title: "Export Test")
        manager.addCard(to: deck.id, front: "Q1", back: "A1")
        manager.addCard(to: deck.id, front: "Q2", back: "A2")
        
        let updatedDeck = manager.deck(withId: deck.id)!
        let csv = manager.exportToAnki(deck: updatedDeck)
        
        let lines = csv.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 2)
    }
    
    func testExportToAnkiQuotesEscaped() {
        let deck = manager.createDeck(title: "Export Test")
        manager.addCard(to: deck.id, front: "Say \"hello\"", back: "Response")
        
        let updatedDeck = manager.deck(withId: deck.id)!
        let csv = manager.exportToAnki(deck: updatedDeck)
        
        // Should escape quotes with double quotes
        XCTAssertTrue(csv.contains("\"\""))
    }
}

// MARK: - FlashcardRating Tests

@MainActor
final class FlashcardRatingTests: BaseTestCase {
    
    func testFlashcardRatingAllCases() {
        let ratings: [FlashcardManager.FlashcardRating] = [.again, .hard, .good, .easy]
        XCTAssertEqual(ratings.count, 4)
    }
    
    func testFlashcardRatingRawValues() {
        XCTAssertEqual(FlashcardManager.FlashcardRating.again.rawValue, 0)
        XCTAssertEqual(FlashcardManager.FlashcardRating.hard.rawValue, 3)
        XCTAssertEqual(FlashcardManager.FlashcardRating.good.rawValue, 4)
        XCTAssertEqual(FlashcardManager.FlashcardRating.easy.rawValue, 5)
    }
    
    func testFlashcardRatingOrdering() {
        XCTAssertLessThan(FlashcardManager.FlashcardRating.again.rawValue, 
                         FlashcardManager.FlashcardRating.hard.rawValue)
        XCTAssertLessThan(FlashcardManager.FlashcardRating.hard.rawValue, 
                         FlashcardManager.FlashcardRating.good.rawValue)
        XCTAssertLessThan(FlashcardManager.FlashcardRating.good.rawValue, 
                         FlashcardManager.FlashcardRating.easy.rawValue)
    }
    
    func testFlashcardRatingFromRawValue() {
        XCTAssertEqual(FlashcardManager.FlashcardRating(rawValue: 0), .again)
        XCTAssertEqual(FlashcardManager.FlashcardRating(rawValue: 4), .good)
        XCTAssertNil(FlashcardManager.FlashcardRating(rawValue: 99))
    }
}
