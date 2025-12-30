#if os(iOS)
import SwiftUI

struct IOSFlashcardsView: View {
    @StateObject private var manager = FlashcardManager.shared
    @StateObject private var coursesStore = CoursesStore.shared ?? CoursesStore()
    @EnvironmentObject private var sheetRouter: IOSSheetRouter
    @State private var selectedDeck: FlashcardDeck?
    @State private var showingAddDeck = false
    @State private var searchText = ""
    
    private var filteredDecks: [FlashcardDeck] {
        if searchText.isEmpty {
            return manager.decks
        }
        return manager.decks.filter { deck in
            deck.title.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if manager.decks.isEmpty {
                    emptyStateView
                } else {
                    deckListView
                }
            }
            .navigationTitle("Flashcards")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search decks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddDeck = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddDeck) {
                IOSAddDeckSheet()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 72))
                .foregroundStyle(.secondary.opacity(0.5))
            
            VStack(spacing: 12) {
                Text("No Flashcard Decks")
                    .font(.title2.weight(.bold))
                
                Text("Create your first deck to start studying with spaced repetition")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                showingAddDeck = true
            } label: {
                Label("Create Deck", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.appBackground)
    }
    
    private var deckListView: some View {
        List {
            ForEach(filteredDecks) { deck in
                NavigationLink(destination: IOSDeckDetailView(deck: deck)) {
                    DeckRowView(deck: deck)
                }
            }
            .onDelete(perform: deleteDecks)
        }
        .listStyle(.insetGrouped)
    }
    
    private func deleteDecks(at offsets: IndexSet) {
        let decksToDelete = offsets.map { filteredDecks[$0] }
        for deck in decksToDelete {
            manager.deleteDeck(deck.id)
        }
    }
}

struct DeckRowView: View {
    let deck: FlashcardDeck
    
    private var dueCount: Int {
        deck.cards.filter { $0.dueDate <= Date() }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(deck.title)
                    .font(.headline)
                
                Spacer()
                
                if dueCount > 0 {
                    Text("\(dueCount)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor, in: Capsule())
                }
            }
            
            HStack(spacing: 16) {
                Label("\(deck.cards.count)", systemImage: "rectangle.stack")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if dueCount > 0 {
                    Label("Due now", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct IOSAddDeckSheet: View {
    @StateObject private var manager = FlashcardManager.shared
    @StateObject private var coursesStore = CoursesStore.shared ?? CoursesStore()
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var selectedCourseId: UUID?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Deck Title", text: $title)
                } header: {
                    Text("Deck Name")
                }
                
                Section {
                    Picker("Course (Optional)", selection: $selectedCourseId) {
                        Text("None").tag(nil as UUID?)
                        ForEach(coursesStore.activeCourses) { course in
                            Text(course.title).tag(course.id as UUID?)
                        }
                    }
                } header: {
                    Text("Link to Course")
                }
            }
            .navigationTitle("New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let _ = manager.createDeck(title: title, courseID: selectedCourseId)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct IOSDeckDetailView: View {
    @StateObject private var manager = FlashcardManager.shared
    @State var deck: FlashcardDeck
    @State private var showingAddCard = false
    @State private var showingStudySession = false
    
    private var deckBinding: Binding<FlashcardDeck> {
        Binding(
            get: { manager.deck(withId: deck.id) ?? deck },
            set: { deck = $0 }
        )
    }
    
    private var dueCards: [Flashcard] {
        manager.dueCards(for: deck.id)
    }
    
    var body: some View {
        List {
            Section {
                if !dueCards.isEmpty {
                    Button {
                        showingStudySession = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Study Now")
                                    .font(.headline)
                                Text("\(dueCards.count) cards due")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("All caught up!")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section {
                HStack {
                    Text("Total Cards")
                    Spacer()
                    Text("\(deck.cards.count)")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Due Now")
                    Spacer()
                    Text("\(dueCards.count)")
                        .foregroundColor(dueCards.isEmpty ? .secondary : .orange)
                }
            } header: {
                Text("Statistics")
            }
            
            Section {
                ForEach(deck.cards) { card in
                    NavigationLink(destination: IOSCardDetailView(card: card, deckId: deck.id)) {
                        CardRowView(card: card)
                    }
                }
                .onDelete { offsets in
                    var updatedDeck = deck
                    updatedDeck.cards.remove(atOffsets: offsets)
                    manager.updateDeck(updatedDeck)
                    deck = updatedDeck
                }
            } header: {
                Text("Cards")
            }
        }
        .navigationTitle(deck.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddCard = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCard) {
            IOSAddCardSheet(deck: deckBinding)
        }
        .sheet(isPresented: $showingStudySession) {
            IOSStudySessionView(deck: deckBinding, dueCards: dueCards)
        }
    }
}

struct CardRowView: View {
    let card: Flashcard
    
    private var isDue: Bool {
        card.dueDate <= Date()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.frontText)
                .font(.body)
                .lineLimit(2)
            
            HStack(spacing: 12) {
                if isDue {
                    Label("Due", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Label(formatDate(card.dueDate), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(card.difficulty.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct IOSAddCardSheet: View {
    @StateObject private var manager = FlashcardManager.shared
    @Environment(\.dismiss) private var dismiss
    @Binding var deck: FlashcardDeck
    
    @State private var frontText = ""
    @State private var backText = ""
    @State private var difficulty: FlashcardDifficulty = .medium
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Front", text: $frontText, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Question")
                }
                
                Section {
                    TextField("Back", text: $backText, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Answer")
                }
                
                Section {
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(FlashcardDifficulty.allCases, id: \.self) { diff in
                            Text(diff.rawValue.capitalized).tag(diff)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Difficulty")
                }
            }
            .navigationTitle("New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        manager.addCard(to: deck.id, front: frontText, back: backText, difficulty: difficulty)
                        dismiss()
                    }
                    .disabled(frontText.isEmpty || backText.isEmpty)
                }
            }
        }
    }
}

struct IOSCardDetailView: View {
    let card: Flashcard
    let deckId: UUID
    @State private var showingBack = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Text(showingBack ? "Answer" : "Question")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                Text(showingBack ? card.backText : card.frontText)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(32)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
            }
            
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showingBack.toggle()
                }
            } label: {
                Label(showingBack ? "Show Question" : "Show Answer", systemImage: "arrow.2.squarepath")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Label("Difficulty", systemImage: "gauge")
                        .font(.caption)
                    Text(card.difficulty.rawValue.capitalized)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.secondary)
                
                if let lastReviewed = card.lastReviewed {
                    HStack(spacing: 12) {
                        Label("Last Reviewed", systemImage: "clock")
                            .font(.caption)
                        Text(lastReviewed, style: .relative)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .padding()
        .navigationTitle("Card Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct IOSStudySessionView: View {
    @StateObject private var manager = FlashcardManager.shared
    @Environment(\.dismiss) private var dismiss
    @Binding var deck: FlashcardDeck
    let dueCards: [Flashcard]
    
    @State private var currentIndex = 0
    @State private var showingBack = false
    @State private var sessionComplete = false
    
    private var currentCard: Flashcard? {
        guard currentIndex < dueCards.count else { return nil }
        return dueCards[currentIndex]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if sessionComplete {
                    completionView
                } else if let card = currentCard {
                    studyCardView(card: card)
                } else {
                    Text("No cards to study")
                }
            }
            .navigationTitle("Study Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func studyCardView(card: Flashcard) -> some View {
        VStack(spacing: 24) {
            // Progress
            HStack {
                Text("\(currentIndex + 1) / \(dueCards.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .padding(.horizontal)
            
            ProgressView(value: Double(currentIndex), total: Double(dueCards.count))
                .padding(.horizontal)
            
            Spacer()
            
            // Card
            VStack(spacing: 16) {
                Text(showingBack ? "Answer" : "Question")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                ScrollView {
                    Text(showingBack ? card.backText : card.frontText)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding(32)
                }
                .frame(maxWidth: .infinity, maxHeight: 300)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
            .padding(.horizontal)
            
            if !showingBack {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showingBack = true
                    }
                } label: {
                    Label("Show Answer", systemImage: "eye")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
            } else {
                ratingButtons(card: card)
            }
            
            Spacer()
        }
        .padding(.vertical)
    }
    
    private func ratingButtons(card: Flashcard) -> some View {
        VStack(spacing: 12) {
            Text("How well did you know this?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                ratingButton(title: "Again", color: .red, rating: .again, card: card)
                ratingButton(title: "Hard", color: .orange, rating: .hard, card: card)
                ratingButton(title: "Good", color: .green, rating: .good, card: card)
                ratingButton(title: "Easy", color: .blue, rating: .easy, card: card)
            }
            .padding(.horizontal)
        }
    }
    
    private func ratingButton(title: String, color: Color, rating: FlashcardManager.FlashcardRating, card: Flashcard) -> some View {
        Button {
            gradeCard(card: card, rating: rating)
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                Text(manager.estimateInterval(card: card, grade: rating))
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .cornerRadius(12)
        }
    }
    
    private func gradeCard(card: Flashcard, rating: FlashcardManager.FlashcardRating) {
        manager.grade(cardId: card.id, in: deck.id, rating: rating)
        
        withAnimation {
            showingBack = false
            currentIndex += 1
            
            if currentIndex >= dueCards.count {
                sessionComplete = true
            }
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
            
            VStack(spacing: 8) {
                Text("Session Complete!")
                    .font(.title.bold())
                
                Text("Reviewed \(dueCards.count) cards")
                    .foregroundStyle(.secondary)
            }
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    IOSFlashcardsView()
        .environmentObject(IOSSheetRouter())
}
#endif
#endif

