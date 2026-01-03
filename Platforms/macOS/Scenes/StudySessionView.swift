#if os(macOS)
import SwiftUI

struct StudySessionView: View {
    let deck: FlashcardDeck
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = FlashcardManager.shared
    
    @State private var currentCards: [Flashcard] = []
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var sessionComplete = false
    @State private var cardsStudied = 0
    @State private var showingAnswer = false
    
    private var currentCard: Flashcard? {
        guard currentIndex < currentCards.count else { return nil }
        return currentCards[currentIndex]
    }
    
    private var progress: Double {
        guard !currentCards.isEmpty else { return 0 }
        return Double(currentIndex) / Double(currentCards.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            if sessionComplete {
                completionView
            } else if let card = currentCard {
                cardView(card)
            } else {
                emptyView
            }
        }
        .frame(width: 700, height: 600)
        .onAppear {
            startSession()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Study Session")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("End session")
            }
            
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(.linear)
            
            HStack {
                Text("\(currentIndex + 1) / \(currentCards.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(cardsStudied) studied")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(.secondaryBackground)
    }
    
    // MARK: - Card View
    
    private func cardView(_ card: Flashcard) -> some View {
        VStack(spacing: 0) {
            // Card content
            ZStack {
                .tertiaryBackground
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Question/Answer
                    VStack(spacing: 16) {
                        Text(showingAnswer ? "Answer" : "Question")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        ScrollView {
                            Text(showingAnswer ? card.backText : card.frontText)
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxHeight: 300)
                    }
                    
                    Spacer()
                    
                    // Show answer button
                    if !showingAnswer {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showingAnswer = true
                            }
                        } label: {
                            Text("Show Answer")
                                .font(.headline)
                                .frame(minWidth: 200)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .keyboardShortcut(.space, modifiers: [])
                    }
                }
                .padding(.vertical, 40)
            }
            
            // Rating buttons
            if showingAnswer {
                Divider()
                
                ratingButtons(for: card)
                    .padding(20)
                    .background(.secondaryBackground)
            }
        }
    }
    
    // MARK: - Rating Buttons
    
    private func ratingButtons(for card: Flashcard) -> some View {
        HStack(spacing: 12) {
            ForEach([
                (rating: FlashcardManager.FlashcardRating.again, title: "Again", color: Color.red, key: "1"),
                (rating: FlashcardManager.FlashcardRating.hard, title: "Hard", color: Color.orange, key: "2"),
                (rating: FlashcardManager.FlashcardRating.good, title: "Good", color: Color.green, key: "3"),
                (rating: FlashcardManager.FlashcardRating.easy, title: "Easy", color: Color.blue, key: "4")
            ], id: \.rating) { item in
                VStack(spacing: 8) {
                    Button {
                        gradeCard(rating: item.rating)
                    } label: {
                        VStack(spacing: 8) {
                            Text(item.title)
                                .font(.headline)
                            
                            Text(manager.estimateInterval(card: card, grade: item.rating))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.bordered)
                    .tint(item.color)
                    .keyboardShortcut(KeyEquivalent(Character(item.key)), modifiers: [])
                }
            }
        }
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            
            Text("Session Complete!")
                .font(.title.bold())
            
            Text("You studied \(cardsStudied) cards")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.defaultAction)
                
                Button("Study Again") {
                    startSession()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("No Cards to Study")
                .font(.headline)
            
            Text("All cards are up to date!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func startSession() {
        currentCards = manager.dueCards(for: deck.id)
        
        // Add new cards if there are slots
        let newCards = deck.cards.filter { $0.repetition == 0 }.prefix(10)
        currentCards.append(contentsOf: newCards)
        
        currentIndex = 0
        cardsStudied = 0
        showingAnswer = false
        sessionComplete = false
    }
    
    private func gradeCard(rating: FlashcardManager.FlashcardRating) {
        guard let card = currentCard else { return }
        
        manager.grade(cardId: card.id, in: deck.id, rating: rating)
        cardsStudied += 1
        
        withAnimation(.spring(response: 0.3)) {
            currentIndex += 1
            showingAnswer = false
            
            if currentIndex >= currentCards.count {
                sessionComplete = true
            }
        }
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    StudySessionView(deck: FlashcardDeck(
        title: "Sample Deck",
        cards: [
            Flashcard(frontText: "What is the capital of France?", backText: "Paris", difficulty: .medium, dueDate: Date()),
            Flashcard(frontText: "What is 2 + 2?", backText: "4", difficulty: .easy, dueDate: Date())
        ]
    ))
}
#endif
#endif
