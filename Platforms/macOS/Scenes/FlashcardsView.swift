#if os(macOS)
import SwiftUI

struct FlashcardsView: View {
    @StateObject private var manager = FlashcardManager.shared
    @EnvironmentObject private var coursesStore: CoursesStore
    @State private var selectedDeck: FlashcardDeck?
    @State private var showingAddDeck = false
    @State private var showingStudySession = false
    @State private var searchText = ""
    
    private var filteredDecks: [FlashcardDeck] {
        if searchText.isEmpty {
            return manager.decks
        }
        return manager.decks.filter { deck in
            deck.title.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var currentSemesterCourses: [Course] {
        let existingDeckCourseIds = Set(manager.decks.compactMap { $0.courseID })
        return coursesStore.currentSemesterCourses.filter { course in
            !existingDeckCourseIds.contains(course.id)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area without sidebar
            if let deck = selectedDeck {
                DeckDetailView(deck: deck) {
                    selectedDeck = nil
                }
            } else {
                deckSelectionView
            }
        }
        .sheet(isPresented: $showingAddDeck) {
            AddDeckSheet()
        }
    }
    
    // MARK: - Deck Selection View
    
    private var deckSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with search and add button
                VStack(spacing: 12) {
                    HStack {
                        Text(NSLocalizedString("flashcards.section.decks", comment: "Decks"))
                            .font(.title.bold())
                        
                        Spacer()
                        
                        Button {
                            showingAddDeck = true
                        } label: {
                            Label(NSLocalizedString("flashcards.action.create_deck", comment: "Create new deck"), systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    TextField(NSLocalizedString("flashcards.search.placeholder", comment: "Search decks"), text: $searchText)
                        .textFieldStyle(.roundedBorder)
                }
                .padding()
                
                Divider()
                
                // Current Semester Courses
                if !currentSemesterCourses.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("flashcards.section.current_semester", comment: "Current Semester"))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 12) {
                            ForEach(currentSemesterCourses) { course in
                                CourseCardView(course: course) {
                                    createDeckForCourse(course)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // All Decks
                if !filteredDecks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("flashcards.section.all_decks", comment: "All Decks"))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 12) {
                            ForEach(filteredDecks) { deck in
                                DeckCardView(deck: deck, isSelected: selectedDeck?.id == deck.id) {
                                    selectedDeck = deck
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                } else if !searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text(NSLocalizedString("flashcards.search.no_results", comment: "No decks found"))
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createDeckForCourse(_ course: Course) {
        // Check if deck already exists for this course
        if let existingDeck = manager.decks.first(where: { $0.courseID == course.id }) {
            selectedDeck = existingDeck
        } else {
            let newDeck = manager.createDeck(title: course.title, courseID: course.id)
            selectedDeck = newDeck
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text(searchText.isEmpty ? NSLocalizedString("flashcards.empty.no_decks", comment: "No Decks") : NSLocalizedString("flashcards.empty.no_results", comment: "No Results"))
                .font(.headline)
            
            if searchText.isEmpty {
                Text(NSLocalizedString("flashcards.empty.create_first", comment: "Create your first flashcard deck to get started"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Button {
                    showingAddDeck = true
                } label: {
                    Label(NSLocalizedString("flashcards.action.new_deck", comment: "New Deck"), systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .frame(maxHeight: .infinity)
    }
    
    private var emptyDetailView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            
            Text(NSLocalizedString("flashcards.empty.select_deck", comment: "Select a Deck"))
                .font(.title2.bold())
            
            Text(NSLocalizedString("flashcards.empty.choose_deck", comment: "Choose a deck from the sidebar to view cards and study"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.tertiaryBackground)
    }
}

// MARK: - Course Card

struct CourseCardView: View {
    let course: Course
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle()
                        .fill(.blue.tertiary)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: "book.fill")
                                .foregroundStyle(.blue)
                        }
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.title)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(NSLocalizedString("Create flashcard deck", value: "Create flashcard deck", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.secondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.quaternary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Deck Card

struct DeckCardView: View {
    let deck: FlashcardDeck
    let isSelected: Bool
    let action: () -> Void
    
    private var dueCount: Int {
        deck.cards.filter { $0.isDue }.count
    }
    
    private var newCount: Int {
        deck.cards.filter { $0.isNew }.count
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: "rectangle.stack.fill")
                                .foregroundStyle(isSelected ? .white : .secondary)
                        }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor)
                            .font(.title3)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(deck.title)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 12) {
                        if dueCount > 0 {
                            Label { Text(verbatim: "\(dueCount)") } icon: { Image(systemName: "clock.fill") }
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        
                        if newCount > 0 {
                            Label { Text(verbatim: "\(newCount)") } icon: { Image(systemName: "sparkle") }
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        
                        Text(verbatim: "\(deck.cards.count) cards")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? .accentQuaternary : .secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .center) {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Course Row

struct CourseRowView: View {
    let course: Course
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon with course color
                Circle()
                    .fill(courseColor)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "book.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }
                
                // Course info
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    
                    Text(course.code)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Add deck indicator
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(String(format: NSLocalizedString("flashcards.deck.help_create", comment: "Create flashcard deck for %@"), course.title))
    }
    
    private var courseColor: Color {
        if let hex = course.colorHex {
            return Color(hex: hex) ?? .accentColor
        }
        return .accentColor
    }
}

// MARK: - Deck Row

struct DeckRowView: View {
    let deck: FlashcardDeck
    let isSelected: Bool
    let action: () -> Void
    
    @StateObject private var manager = FlashcardManager.shared
    
    private var dueCount: Int {
        manager.dueCards(for: deck.id).count
    }
    
    private var newCount: Int {
        deck.cards.filter { $0.repetition == 0 }.count
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Circle()
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(isSelected ? .white : .secondary)
                    }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(deck.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? .primary : .primary)
                    
                    HStack(spacing: 8) {
                        if dueCount > 0 {
                            Label { Text(verbatim: "\(dueCount)") } icon: { Image(systemName: "clock.fill") }
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        
                        if newCount > 0 {
                            Label { Text(verbatim: "\(newCount)") } icon: { Image(systemName: "sparkle") }
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        
                        Text("\(deck.cards.count) \(NSLocalizedString("flashcards.deck.cards_count", comment: "%d cards"))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? .accentQuaternary : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Deck Sheet

struct AddDeckSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = FlashcardManager.shared
    
    @State private var title = ""
    @State private var selectedCourse: UUID?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text(NSLocalizedString("flashcards.add.title", comment: "New Deck"))
                    .font(.title2.bold())
                
                Spacer()
                
                Button(NSLocalizedString("flashcards.add.button_cancel", comment: "Cancel")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Divider()
            
            // Form
            Form {
                Section {
                    TextField(NSLocalizedString("flashcards.add.name_field", comment: "Deck Name"), text: $title)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section(NSLocalizedString("flashcards.add.link_section", comment: "Link to Course (Optional)")) {
                    Text(NSLocalizedString("flashcards.add.coming_soon", comment: "Course selection coming soon"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            
            Spacer()
            
            // Actions
            HStack {
                Spacer()
                
                Button(NSLocalizedString("flashcards.add.button_cancel", comment: "Cancel")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button(NSLocalizedString("flashcards.add.button_create", comment: "Create")) {
                    createDeck()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 400, height: 300)
    }
    
    private func createDeck() {
        _ = manager.createDeck(title: title, courseID: selectedCourse)
        dismiss()
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    FlashcardsView()
}
#endif
#endif
