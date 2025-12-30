#if os(macOS)
import SwiftUI

struct DeckDetailView: View {
    let deck: FlashcardDeck
    
    @StateObject private var manager = FlashcardManager.shared
    @State private var showingAddCard = false
    @State private var showingStudySession = false
    @State private var showingDeckSettings = false
    @State private var selectedTab: DeckTab = .cards
    
    enum DeckTab: String, CaseIterable {
        case cards = "Cards"
        case statistics = "Statistics"
        
        var systemImage: String {
            switch self {
            case .cards: return "square.stack.3d.up"
            case .statistics: return "chart.bar"
            }
        }
    }
    
    private var currentDeck: FlashcardDeck? {
        manager.deck(withId: deck.id)
    }
    
    private var dueCards: [Flashcard] {
        manager.dueCards(for: deck.id)
    }
    
    private var newCards: [Flashcard] {
        currentDeck?.cards.filter { $0.repetition == 0 } ?? []
    }
    
    private var learningCards: [Flashcard] {
        currentDeck?.cards.filter { $0.repetition > 0 && $0.repetition < 3 } ?? []
    }
    
    private var reviewCards: [Flashcard] {
        currentDeck?.cards.filter { $0.repetition >= 3 } ?? []
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Tab Picker
            Picker("View", selection: $selectedTab) {
                ForEach(DeckTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.systemImage)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(20)
            
            // Content
            switch selectedTab {
            case .cards:
                cardsView
            case .statistics:
                statisticsView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
        .sheet(isPresented: $showingAddCard) {
            AddCardSheet(deck: deck)
        }
        .sheet(isPresented: $showingStudySession) {
            StudySessionView(deck: deck)
        }
        .sheet(isPresented: $showingDeckSettings) {
            DeckSettingsSheet(deck: deck)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.title)
                    .font(.title2.bold())
                
                HStack(spacing: 12) {
                    if dueCards.count > 0 {
                        Label("\(dueCards.count) due", systemImage: "clock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                    
                    Text("\(currentDeck?.cards.count ?? 0) cards")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button {
                    showingStudySession = true
                } label: {
                    Label("Study", systemImage: "brain.head.profile")
                }
                .buttonStyle(.borderedProminent)
                .disabled(dueCards.isEmpty && newCards.isEmpty)
                .help(dueCards.isEmpty && newCards.isEmpty ? "No cards to study" : "Start study session")
                
                Button {
                    showingAddCard = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
                .help("Add new card")
                
                Button {
                    showingDeckSettings = true
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.bordered)
                .help("Deck settings")
            }
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Cards View
    
    private var cardsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let deck = currentDeck, !deck.cards.isEmpty {
                    // Card sections
                    if !newCards.isEmpty {
                        cardSection(title: "New", icon: "sparkle", color: .blue, cards: newCards)
                    }
                    
                    if !dueCards.isEmpty {
                        cardSection(title: "Due", icon: "clock.fill", color: .orange, cards: dueCards)
                    }
                    
                    if !learningCards.isEmpty {
                        cardSection(title: "Learning", icon: "book", color: .green, cards: learningCards)
                    }
                    
                    if !reviewCards.isEmpty {
                        cardSection(title: "Review", icon: "checkmark.circle", color: .purple, cards: reviewCards)
                    }
                } else {
                    emptyCardsView
                }
            }
            .padding(20)
        }
    }
    
    private func cardSection(title: String, icon: String, color: Color, cards: [Flashcard]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(color)
                
                Text("\(cards.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(cards) { card in
                    FlashcardRowView(card: card, deckId: deck.id)
                }
            }
        }
    }
    
    private var emptyCardsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.badge.a")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("No Cards Yet")
                .font(.headline)
            
            Text("Add your first flashcard to start studying")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button {
                showingAddCard = true
            } label: {
                Label("Add Card", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Statistics View
    
    private var statisticsView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                statCard(
                    title: "Total Cards",
                    value: "\(currentDeck?.cards.count ?? 0)",
                    icon: "square.stack.3d.up",
                    color: .blue
                )
                
                statCard(
                    title: "Due Today",
                    value: "\(dueCards.count)",
                    icon: "clock.fill",
                    color: .orange
                )
                
                statCard(
                    title: "New Cards",
                    value: "\(newCards.count)",
                    icon: "sparkle",
                    color: .green
                )
                
                statCard(
                    title: "Review Cards",
                    value: "\(reviewCards.count)",
                    icon: "checkmark.circle",
                    color: .purple
                )
            }
            .padding(20)
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 36, weight: .bold))
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

// MARK: - Flashcard Row

struct FlashcardRowView: View {
    let card: Flashcard
    let deckId: UUID
    
    @State private var isFlipped = false
    @State private var showingEdit = false
    @StateObject private var manager = FlashcardManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(card.frontText)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                
                if isFlipped {
                    Text(card.backText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    if card.repetition > 0 {
                        Text("Interval: \(card.interval)d")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    
                    if let lastReviewed = card.lastReviewed {
                        Text("Last: \(lastReviewed, style: .relative)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 4) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isFlipped.toggle()
                    }
                } label: {
                    Image(systemName: isFlipped ? "eye.slash" : "eye")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help(isFlipped ? "Hide answer" : "Show answer")
                
                Button {
                    showingEdit = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Edit card")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .contextMenu {
            Button {
                showingEdit = true
            } label: {
                Label("Edit Card", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                deleteCard()
            } label: {
                Label("Delete Card", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditCardSheet(card: card, deckId: deckId)
        }
    }
    
    private var statusColor: Color {
        if card.repetition == 0 {
            return .blue
        } else if card.dueDate <= Date() {
            return .orange
        } else {
            return .green
        }
    }
    
    private func deleteCard() {
        if let deckIndex = manager.decks.firstIndex(where: { $0.id == deckId }) {
            var deck = manager.decks[deckIndex]
            deck.cards.removeAll { $0.id == card.id }
            manager.updateDeck(deck)
        }
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    DeckDetailView(deck: FlashcardDeck(title: "Sample Deck", cards: [
        Flashcard(frontText: "Question 1", backText: "Answer 1", difficulty: .medium, dueDate: Date()),
        Flashcard(frontText: "Question 2", backText: "Answer 2", difficulty: .easy, dueDate: Date())
    ]))
}
#endif
#endif
